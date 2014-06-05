require "nokogiri"
require "savage"
require "yaml"
require_relative "svg"
require "pp"

module Savage
  class Path
  end #Path
  class Direction
    def clone
      Marshal::load(Marshal.dump(self))
    end
  end
  module Directions
    class LineTo < PointTarget
      attr_accessor :rate

      def length(start_point)
        Math.sqrt((start_point.x-target.x)*(start_point.x-target.x)+(start_point.y-target.y)*(start_point.y-target.y))
      end

      def split(start_point, size)
        n = (self.length(start_point) / (size+1)).ceil
        dx = (target.x-start_point.x)/n
        dy = (target.y-start_point.y)/n

        result = []
        n.times do |i|
          result << Savage::Directions::LineTo.new(start_point.x + dx*(i+1), start_point.y + dy*(i+1))
        end
        result
      end
    end #Line_to
    class MoveTo < PointTarget
      def split(start_point, size)
        self
      end
    end
  end #directions
end #module

class SVGFile
  attr_reader :paths, :elements, :properties, :whole_path, :tpath, :width, :height, :splitted_path

  def initialize(file_name)
    @allowed_elements = ['path']
    @paths = []
    @whole_path = Savage::Path.new
    @tpath = Savage::Path.new
    @splitted_path = Savage::Path.new
    @elements = []
    @properties = {}
    @file_name = file_name
    read_svg @file_name
    absolute!
    read_properties
    read_whole_path
    split
    make_tpath
  end

  def split
    start_point = nil
    size = @properties['maxSegmentLength']
    @whole_path.subpaths.first.directions.each do |direction|
      next if direction.kind_of? Savage::Directions::ClosePath
      end_point = direction.target
      new_directions = direction.split start_point, size
      @splitted_path.subpaths.first.directions << new_directions
      start_point = end_point
    end
    @splitted_path.subpaths.first.directions.flatten!
    @splitted_path.close_path
  end

  def make_gcode_file
    begin
      # f = File.new Time.now.strftime("%d-%b-%y %H:%M:%S").to_s + '.gcode', 'w+'
      f = File.new 'result.gcode', 'w+'
      f.write "(#{@file_name})\n"
      f.write "(#{Time.now.strftime("%d-%b-%y %H:%M:%S").to_s})\n"
      f.write "(#{@properties})\n"
      f.write "%\n"
      f.write "G51Y-1\n"
      start_point = nil
      @tpath.subpaths.first.directions.each do |direction|
        next if direction.kind_of? Savage::Directions::ClosePath
        case direction.command_code
          when 'M'
            f.write "G00 X#{direction.target.x} Y#{direction.target.y} Z0\n"
          when 'L'
            f.write "G01 X#{direction.target.x} Y#{direction.target.y} Z10 F#{@properties["linearVelocity"]/direction.rate}\n"
        end
        start_point = direction.target
      end
      f.write "M30\n"
      f.write "%\n"
      f.close
    rescue Exception => e
      p e.message
      p e.backtrace[0..2]
    end

  end

  def absolute!
    @paths.each(&:absolute!)
  end

  def make_tpath
    x = y = 0
    path = @splitted_path.clone
    path.subpaths.each do |subpath|
      start_point_linear = nil
      start_point_triangle = nil
      subpath.directions.each do |direction|
        next if direction.kind_of? Savage::Directions::ClosePath
        tdirection = direction.clone

        x = direction.target.x
        y = direction.target.y

        tdirection.target.x = Math.sqrt(x*x + y*y)
        tdirection.target.y = Math.sqrt((@properties["canvasSizeX"]-x)*(@properties["canvasSizeX"]-x) + y*y)
        tdirection.rate = tdirection.length(start_point_triangle) / direction.length(start_point_linear) if direction.command_code == 'L'

        @tpath.subpaths[0].directions << tdirection

        start_point_linear = direction.target
        start_point_triangle = tdirection.target
      end
    end
    @tpath.close_path
  end

  def read_svg(file_name)
    svg = Nokogiri::XML File.open file_name
    svg.traverse do |e|
      @elements.push e if e.element? && @allowed_elements.include?(e.name)
    end
    @elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map! { |path| Savage::Parser.parse path }
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def read_properties
    @properties = File.open("properties.yml") { |yf| YAML::load(yf) }
  end

  def read_whole_path
    @paths.each do |path|
      path.subpaths.each do |subpath|
        subpath.directions.each_with_index do |direction, i|
          @whole_path.subpaths.first.directions << direction unless direction.kind_of? Savage::Directions::ClosePath
        end
      end
    end
    @whole_path.close_path
  end

  def save(file_name, paths)

    output_file = SVG.new(@width, @height)
    output_file.svg << output_file.marker("point", 6, 6)
    paths.each_with_index do |path, i|
      output_file.svg << output_file.path(path.to_command, "fill: none; stroke: black; stroke-width: 3; marker-start: url(#point)")
    end
    output_file.save(file_name)
  end
end

# file_name = ARGV[0] || Dir.pwd + '/Domik.svg'
file_name = ARGV[0] || Dir.pwd + '/rack.svg'

svg_file = SVGFile.new file_name
paths = svg_file.paths
tpath = [svg_file.tpath]
p svg_file.properties
# pp svg_file.splitted_path
# svg_file.save 'output.svg', [svg_file.whole_path]
svg_file.save 'output.svg', tpath
svg_file.make_gcode_file
