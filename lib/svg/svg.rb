require 'nokogiri'
require 'yaml'
require_relative 'path/path'

class SVG
  attr_accessor :paths, :splitted_paths, :tpaths
  attr_reader :width, :height, :properties

  def initialize(file_name, properties_file_name = 'properties.yml')
    @splitted_paths = []
    @tpaths = []
    read_svg file_name
    read_properties properties_file_name
    optimize
    split @properties['max_segment_length']
    make_tpath

  end

  def save(file_name, paths)
    dimensions = calculate_dimensions(paths)
    start_point = Point.new(@properties['initial_x'], @properties['initial_y'])
    builder = Nokogiri::XML::Builder.new do |xml|
      #header and styles
      xml.doc.create_internal_subset(
          'svg',
          '-//W3C//DTD SVG 1.1//EN',
          'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
      )
      xml.svg(version: '1.1',
              xmlns: 'http://www.w3.org/2000/svg',
              'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
              x: 0, y: 0,
              width: dimensions[2], height: dimensions[3],
              viewBox: "0, 0, #{dimensions[2]}, #{dimensions[3]}") {
        xml.marker(id: 'arrow-end',
                   markerWidth: 8, markerHeight: 8,
                   refX: '2%', refY: 4,
                   markerUnits: 'userSpaceOnUse', orient: 'auto') {
          xml.polyline(points: '0,0 8,4 0,8 2,4 0,0',
                       'stroke-width' => 1, stroke: 'darkred', fill: 'red')
        }
        xml.style 'path {stroke-width: 2; fill: none;}'
        xml.style '.stroke {stroke: black;}'
        xml.style '.move_to {stroke: red; marker-end: url(#arrow-end);}'
        xml.style 'path:hover {stroke-width: 4;}'

        #first move_to line
        finish = paths.first.directions.first.finish
        xml.path(id: "move_0", d: "M #{start_point.x},#{start_point.y} L #{finish.x}, #{finish.y} ", class: 'move_to')

        #main
        paths.each_index do |i|
          xml.path(d: paths[i].d, id: "path_#{i}", class: 'stroke')
          if i < paths.size-1
            start = paths[i].directions.last.finish
            finish = paths[i+1].directions.first.finish
            unless start.x.round == finish.x.round && start.y.round == finish.y.round
              xml.path(id: "move_#{i+1}", d: "M #{start.x},#{start.y} L #{finish.x}, #{finish.y} ", class: 'move_to')
            end
          end

        end

        #last move_to line
        start = paths.last.directions.last.finish
        finish = start_point
        xml.path(id: "move_#{paths.size}", d: "M #{start.x},#{start.y} L #{finish.x}, #{finish.y} ", class: 'move_to')
      }
    end

    File.open(file_name, 'w') { |f| f.write builder.to_xml }
    print "Saved to #{file_name}\n"
  end

  def save_html(file_name)
    file_name.sub!('./result/', '')
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head(lang: 'en') {
          doc.meta(charset: 'utf-8')
          doc.script(src: 'paint.js')
        }
        doc.body {
          doc.object(data: "../result/#{file_name}.svg", type: 'image/svg+xml', id: 'result')
          doc.div(style: 'margin: auto 40%;') {
            doc.button(style: 'width: 100%; height: 60px;', autofocus: 'true', onclick: "paint('result')") {
              doc << 'Paint'
            }
          }
        }
      }
    end

    File.open("./html/#{file_name}.html", 'w') { |f| f.write builder.to_html }
    print "Saved to ./html/#{file_name}.html\n"
  end

  def make_gcode_file(file_name, properties, paths)
    begin
      f = File.new file_name, 'w+'
      f.puts "(#{file_name})"
      f.puts "(#{Time.now.strftime('%d-%b-%y %H:%M:%S').to_s})"
      properties.each_pair { |pair| f.puts "(#{pair})" }
      f.puts '%'
      #f.puts 'G51Y-1'
      directions = []
      paths.flatten.each do |subpath|
        directions += subpath.directions
      end
      initial_x = properties['initial_x'].to_f.round(2)
      initial_y = properties['initial_y'].to_f.round(2)
      directions.each do |direction|
        x = (direction.finish.x - initial_x).round(2)
        y = (direction.finish.y - initial_y).round(2)
        case direction.command_code
          when 'M'
            f.puts 'G00 Z0' unless direction.start.nil?
            f.puts "G00 X#{x} Y#{y} Z0" unless direction.start.nil?
          when 'L'
            feed = (properties['linear_velocity'] * direction.rate).round(2)
            f.puts "G01 X#{x} Y#{y} Z10 F#{feed}"
          else
            raise ArgumentError "Bad command in tpath #{direction.command_code}"
        end
      end
      f.puts 'G00 Z0'
      f.puts 'G00 X0 Y0 Z0'
      f.puts 'M30'
      f.close
    rescue Exception => e
      p e.message
      p e.backtrace[0..5].join
    end
    print "Saved to #{file_name}\n"
  end

  private
  def optimize
    point = Point.new @properties['initial_x'], @properties['initial_y']
    optimized_paths = []

    until @paths.empty?
      closest, reversed = find_closest(point, @paths)
      @paths.delete closest
      if reversed
        optimized_paths << closest.reversed
        point = closest.reversed.directions.last.finish
      else
        optimized_paths << closest
        point = closest.directions.last.finish
      end

    end
    @paths = optimized_paths
  end

  def find_closest(point, raw_paths)
    closest_distance = Float::INFINITY
    closest_path = nil
    to_reverse = false

    raw_paths.each do |subpath|
      start_point = subpath.directions.first.start
      finish_point = subpath.directions.last.finish
      distance_to_start = Math.sqrt((start_point.x-point.x)*(start_point.x-point.x) + (start_point.y-point.y)*(start_point.y-point.y))
      distance_to_finish = Math.sqrt((finish_point.x-point.x)*(finish_point.x-point.x) + (finish_point.y-point.y)*(finish_point.y-point.y))

      if (distance_to_start < closest_distance) && (distance_to_start <= distance_to_finish)
        closest_path = subpath
        closest_distance = distance_to_start
        to_reverse = false
      end

      if (distance_to_finish < closest_distance) && (distance_to_finish < distance_to_start)
        closest_path = subpath
        closest_distance = distance_to_finish
        to_reverse = true
      end

    end
    return closest_path, to_reverse
  end

  def read_svg(file_name)
    @paths = []
    elements = []
    svg = Nokogiri::XML open file_name
    svg.traverse do |e|
      elements.push e if e.element?
    end
    elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map! { |path| Path.parse path }.flatten!
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def make_tpath
    @splitted_paths.each do |path|
      @tpaths << TPath.new(path, @properties['canvas_size_x']).tpath
    end
  end

  def calculate_dimensions(paths)
    max_x = -Float::INFINITY
    max_y = -Float::INFINITY

    min_x = Float::INFINITY
    min_y = Float::INFINITY

    paths.each do |path|
      min_x = path.dimensions[0] if path.dimensions[0] < min_x
      min_y = path.dimensions[1] if path.dimensions[1] < min_y
      max_x = path.dimensions[2] if path.dimensions[2] > max_x
      max_y = path.dimensions[3] if path.dimensions[3] > max_y
    end
    [min_x, min_y, max_x, max_y]
  end

  def read_properties(file_name)
    @properties = File.open(file_name) { |f| YAML::load(f) }
  end

  def split(size)
    @paths.each do |path|
      @splitted_paths << path.split(size)
    end
  end

end