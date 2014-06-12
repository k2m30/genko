require 'nokogiri'
require 'yaml'
require 'open-uri'

class SVGFile
  attr_reader :paths, :properties, :whole_path, :tpath

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
    close_paths
    read_properties
    read_whole_path
    split
    make_tpath
  end

  def close_paths
    @paths.each do |path|
      path.subpaths.each do |subpath|
        if subpath.directions.last.kind_of? Savage::Directions::ClosePath
          point = find_first_point(subpath)
          size = subpath.directions.size
          subpath.directions[size-1] = Savage::Directions::LineTo.new(point.x, point.y)
        end
      end
    end
  end

  def split
    start_point = nil
    size = @properties['max_segment_length']
    @whole_path.subpaths.first.directions.each_with_index do |direction, i|
      next if direction.kind_of? Savage::Directions::ClosePath
      if %w[S s T t].include? direction.command_code # smooth curves need second control point of previous curve
        new_directions = direction.split start_point, size, @whole_path.subpaths.first.directions[i-1].control_2
      else
        new_directions = direction.split start_point, size
      end

      @splitted_path.subpaths.first.directions << new_directions
      start_point = direction.target
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
      @properties.each_pair { |pair| f.write "(#{pair})\n" }
      f.write "%\n"
      #f.write "G51Y-1\n"
      start_point = nil
      @tpath.subpaths.first.directions.each do |direction|
        next if direction.kind_of? Savage::Directions::ClosePath
        x = (direction.target.x - @properties["initial_x"].to_f).round(2)
        y = (direction.target.y - @properties["initial_y"].to_f).round(2)
        case direction.command_code
          when 'M'
            f.write "G00 Z0\n"
            f.write "G00 X#{x} Y#{y} Z0\n"
          when 'L'
            feed = (@properties["linear_velocity"] * direction.rate).round(2)
            f.write "G01 X#{x} Y#{y} Z4 F#{feed}\n"
          else
            raise ArgumentError "Bad command in tpath #{direction.command_code}"
        end
        start_point = direction.target
      end
      f.write "G00 Z0\n"
      f.write "G00 X0 Y0 Z0\n"
      f.write "M30\n"
      #f.write "%\n"
      f.close
    rescue Exception => e
      p e.message
      p e.backtrace[0..5].join
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
        tdirection.target.y = Math.sqrt((@properties["canvas_size_x"]-x)*(@properties["canvas_size_x"]-x) + y*y)
        tdirection.rate = tdirection.length(start_point_triangle) / direction.length(start_point_linear) if direction.command_code == 'L'
        @tpath.subpaths[0].directions << tdirection

        start_point_linear = direction.target
        start_point_triangle = tdirection.target
      end
    end
    @tpath.close_path
  end

  def read_svg(file_name)
    svg = Nokogiri::XML open file_name
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
    dimensions = calculate_dimensions(paths)
    output_file = SVG.new(dimensions[0]+10, dimensions[1]+10)
    output_file.svg << output_file.marker("point", 6, 6)
    paths.each do |path|
      output_file.svg << output_file.path(path.to_command, "fill: none; stroke: black; stroke-width: 3; marker-start: url(#point)")
    end
    output_file.save(file_name)
    print "Saved to ./#{file_name}\n"
  end

  private
  def calculate_dimensions(paths)
    height = width = 0
    paths.each do |path|
      path.subpaths.each do |subpath|
        subpath.directions.each do |direction|
          next if direction.kind_of? Savage::Directions::ClosePath
          width = direction.target.x if direction.target.x > width
          height = direction.target.y if direction.target.y > height
        end
      end
    end
    [width, height]
  end

  def find_first_point(subpath)
    start_point = nil
    subpath.directions.each do |direction|
      return start_point unless %w[M m].include? direction.command_code
      start_point = direction.target
    end
  end
end