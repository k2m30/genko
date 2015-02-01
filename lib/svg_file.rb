require 'nokogiri'
require 'yaml'
require 'open-uri'


class SVGFile
  attr_reader :paths, :properties, :whole_path, :tpath, :splitted_path

  COLORS = %w[red yellow green white black grey blue]

  def initialize(file_name)
    @allowed_elements = ['path']
    @paths = []
    @whole_path = Savage::Path.new
    @tpath = Savage::Path.new
    @splitted_path = Savage::Path.new
    @arris_highlighted_path = Savage::Path.new
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
    # highlight_arris
  end

  def highlight_arris
    # @tpath.calculate_angles!
    @whole_path.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    @whole_path.calculate_angles!
    pp @whole_path
  end

  def close_paths
    @paths.each do |path|
      path.subpaths.each do |subpath|
        if subpath.directions.last.kind_of? Savage::Directions::ClosePath
          point = find_first_point(subpath)
          subpath.directions[-1] = Savage::Directions::LineTo.new(point.x, point.y) unless point == subpath.directions[-2].target
        end
      end
    end
  end

  def split
    # start_point = nil
    size = @properties['max_segment_length']
    @whole_path.directions.each_with_index do |direction, i|
      if %w[S s T t].include? direction.command_code # smooth curves need second control point of previous curve
        new_directions = direction.split size, @whole_path.subpaths.first.directions[i-1].control_2
      else
        new_directions = direction.split size
      end

      subpath = Savage::SubPath.new
      subpath.directions = new_directions
      @splitted_path.subpaths << subpath
      # start_point = direction.target
    end
    @splitted_path.directions.flatten!
    @splitted_path.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    @splitted_path.calculate_angles!
  end

  def make_gcode_file file_name
    begin
      f = File.new file_name, 'w+'
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
            f.write "G01 X#{x} Y#{y} Z12 F#{feed}\n"
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
    path = @splitted_path.clone
    path.directions.each do |direction|
      tdirection = direction.clone
      tdirection.position = point_transform(direction.position)
      tdirection.target = point_transform(direction.target)

      tdirection.rate = tdirection.length / direction.length if direction.command_code == 'L'
      @tpath.subpaths.first.directions << tdirection
      @tpath.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
      @tpath.calculate_angles!
    end
  end

  def point_transform(point)
    w = @properties["canvas_size_x"]

    x = point.x
    y = point.y
    lx = Math.sqrt(x*x + y*y)

    x = point.x
    y = point.y
    ly = Math.sqrt((w-x)*(w-x) + y*y)

    Savage::Directions::Point.new lx, ly
  end


  def point_to_triangle(x, y)
    dx = @properties["dx"]
    dy = @properties["dy"]
    w = @properties["canvas_size_x"]

    x = x - dx/2
    y = y - dy
    lx = Math.sqrt(x*x + y*y)
    x = x + dx
    ly = Math.sqrt((w-x)*(w-x) + y*y)

    [lx - @properties["initial_x"], ly - @properties["initial_y"]]
  end

  def tpoint_to_decart(lx, ly)
    dx = @properties["dx"]
    dy = @properties["dy"]
    w = @properties["canvas_size_x"]

    lx += @properties["initial_x"]
    ly += @properties["initial_y"]


    x = ((lx*lx - ly*ly + w*w - w * dx)/(2*(w-dx))).round(3)
    y = (Math.sqrt(lx*lx - (x-dx/2)*(x-dx/2))+dy).round(3)

    [x, y]
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
      path.close_path if path.directions.last.kind_of? Savage::Directions::ClosePath
    end
    @whole_path.subpaths.first.directions << Savage::Directions::MoveTo.new(@properties['initial_x'], @properties['initial_y'])
    @whole_path.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    @whole_path.calculate_angles!
  end

  def save(file_name, paths)
    dimensions = calculate_dimensions(paths)
    output_file = SVG.new(dimensions[0]+10, dimensions[1]+10)
    output_file.svg << output_file.marker("point", 6, 6)
    paths.each do |path|
      output_file.svg << output_file.path(path.to_command, "fill: none; stroke: black; stroke-width: 15; marker-start: url(#point)")
    end
    output_file.save(file_name)
    print "Saved to #{file_name}\n"
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
