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
    split @properties['max_segment_length']
    make_tpath

  end

  def read_properties(file_name)
    @properties = File.open(file_name) { |f| YAML::load(f) }
  end

  def split(size)
    @paths.each do |path|
      subpaths = []
      path.each do |subpath|
        subpaths << subpath.split(size)
      end
      @splitted_paths << subpaths
    end
  end

  def save(file_name, paths)
    dimensions = calculate_dimensions(paths)

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset(
          'svg',
          '-//W3C//DTD SVG 1.1//EN',
          'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
      )
      xml.svg(version: '1.1', xmlns: 'http://www.w3.org/2000/svg', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
              x: 0, y: 0, width: dimensions[2], height: dimensions[3], viewBox: "0, 0, #{dimensions[2]}, #{dimensions[3]}") {
        xml.marker(id: 'arrow-start', markerWidth: 8, markerHeight: 8, refX: '-2%', refY: 4, markerUnits: 'userSpaceOnUse', orient: 'auto') {
          xml.polyline(points: '0,0 8,4 0,8 2,4 0,0', 'stroke-width' => 1, stroke: 'darkred', fill: 'red')
        }
        xml.marker(id: 'arrow-end', markerWidth: 8, markerHeight: 8, refX: '2%', refY: 4, markerUnits: 'userSpaceOnUse', orient: 'auto') {
          xml.polyline(points: '0,0 8,4 0,8 2,4 0,0', 'stroke-width' => 1, stroke: 'darkred', fill: 'red')
        }
        xml.style 'g.stroke path:hover {stroke-width: 2;}'
        xml.style 'g.move_to path:hover{stroke-width: 2;}'

        paths.each_with_index do |path, i|
          start = i.zero? ? Point.new(@properties['initial_x'], @properties['initial_y']) : paths[i-1].last.directions.last.finish
          finish = path.first.directions.first.finish
          xml.g(class: 'move_to', stroke: 'red', 'stroke-width' => 1, fill: 'none', 'marker-start' => 'arrow-start', 'marker-end' => 'arrow-end') {
            xml.path(d: "M #{start.x},#{start.y} L #{finish.x}, #{finish.y} ", id: "move_#{i}")
          }

          path.each_with_index do |subpath, j|
            xml.g(class: 'stroke', stroke: 'black', 'stroke-width' => 1, fill: 'none', 'marker-start' => 'none', 'marker-end' => 'none') {
              xml.path(d: subpath.d, id: "path_#{i*j+i}")
            }
          end
        end
      }
    end

    File.open(file_name, 'w') { |f| f.write builder.to_xml }
    p "Saved to #{file_name}"
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
    p "Saved to #{file_name}"
  end

  private
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
    @paths.flatten!.map!(&:value).map! { |path| Path.parse path } #.flatten!
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def make_tpath
    @splitted_paths.each do |path|
      subpaths = []
      path.each do |subpath|
        subpaths << TPath.new(subpath, @properties['canvas_size_x']).tpath
      end
      @tpaths << subpaths
    end
  end


  def calculate_dimensions(paths)
    max_x = -Float::INFINITY
    max_y = -Float::INFINITY

    min_x = Float::INFINITY
    min_y = Float::INFINITY

    paths.each do |path|
      path.each do |subpath|
        min_x = subpath.dimensions[0] if subpath.dimensions[0] < min_x
        min_y = subpath.dimensions[1] if subpath.dimensions[1] < min_y
        max_x = subpath.dimensions[2] if subpath.dimensions[2] > max_x
        max_y = subpath.dimensions[3] if subpath.dimensions[3] > max_y
      end
    end
    [min_x, min_y, max_x, max_y]
  end

end
