require "nokogiri"
require "savage"
require "yaml"
require_relative "svg"
require "pp"

module Savage
  class Path
    def absolute!
      x = y = 0
      start_point = end_point = nil
      @subpaths.each do |subpath|
        subpath.directions.each_with_index do |direction, i|
          next if direction.kind_of? Savage::Directions::ClosePath
          if direction.target.kind_of?(Savage::Directions::Point)
            x = direction.target.x
            y = direction.target.y
          end

          end_point = direction.target
          unless end_point.kind_of? Savage::Directions::Point
            case direction.class.to_s
            when 'Savage::Directions::HorizontalTo'
              x = direction.target
              y  = 0 unless direction.absolute?
              end_point = Savage::Directions::Point.new(x,y)
              direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
            when 'Savage::Directions::VerticalTo'
              x = 0 unless direction.absolute?
              y = direction.target
              end_point = Savage::Directions::Point.new(x,y)
              direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
            else
              raise ArgumentError, "Unknown element: #{direction.class}"
            end #case
          end #unless
          end_point = direction.target
          if direction.relative?
            begin
              x += start_point.x
              y += start_point.y
              end_point = Savage::Directions::Point.new(x,y)
              direction.absolute = true
              direction.target = end_point
            rescue => e
              p e.message
              p e.backtrace[0..2]
            end #rescue
          end #unless
          subpath.directions[i] = direction
          start_point = end_point
        end #each
      end #each
    end #absolute
  end #Path
end #module

class SVGFile
  attr_reader :paths, :elements, :properties, :whole_path, :tpath, :width, :height

  def initialize(file_name)
    @allowed_elements = ['path']
    @paths = []
    @whole_path = Savage::Path.new
    @tpath = Savage::Path.new
    @elements = []
    @properties = {}
    read_svg file_name
    absolute!
    read_properties
    read_whole_path
    # make_tpath
  end

  def absolute!
    @paths.each(&:absolute!)
  end

  def make_tpath
    direction.target.x = Math.sqrt(x*x + y*y)
    direction.target.y = Math.sqrt((@properties["canvasSizeX"]-x)*(@properties["canvasSizeX"]-x) + y*y)
    @tpath.subpaths[0].directions << direction
  end
  def read_svg(file_name)
    svg = Nokogiri::XML File.open file_name
    svg.traverse do |e|
      @elements.push e if e.element? &&  @allowed_elements.include?(e.name)
    end
    @elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map!{ |path| Savage::Parser.parse path}
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
          @whole_path.subpaths[0].directions << direction
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

file_name = ARGV[0] || Dir.pwd + '/Domik.svg'

svg_file = SVGFile.new file_name
paths = svg_file.paths
tpath = [svg_file.tpath]



# p svg_file.properties
# p svg_file.properties
# p paths[0].subpaths[1]
# paths[0].subpaths[1].absolute!
svg_file.save 'output.svg', paths
