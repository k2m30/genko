require 'nokogiri'
require 'yaml'
require_relative 'path/path'

class SVG
  attr_accessor :paths, :splitted_paths, :tpaths
  attr_reader :width, :height

  def initialize(file_name, properties_file_name = 'properties.yml')
    @splitted_paths = []
    @tpaths = []
    read_svg file_name
    read_properties properties_file_name
    split @properties['max_segment_length']

  end

  def read_properties(file_name)
    @properties = File.open(file_name) { |yf| YAML::load(yf) }
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
    @paths.flatten!.map!(&:value).map! { |path| Path.parse path }#.flatten!
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def tpath!
    @splitted_paths.each { |path| @tpaths << path.tpath(size) }
  end

  def make_tpath!
    @tpath = Savage::Path.new
    path = @splitted_path.clone
    path.directions.each do |direction|
      tdirection = direction.clone
      tdirection.position = point_transform(direction.position)
      tdirection.target = point_transform(direction.target)

      tdirection.rate = tdirection.length / direction.length

      subpath = Savage::SubPath.new
      subpath.directions = [tdirection]
      @tpath.subpaths << subpath
    end
    @tpath.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    @tpath.calculate_angles!
    l = @tpath.length
    @properties[:g00] = l[:length_g00]
    @properties[:g01] = l[:length_g01]
  end

  class << self

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
            path.each_with_index do |subpath, j|
              xml.g(class: 'stroke', stroke: 'black', 'stroke-width' => 1, fill: 'none', 'marker-start' => 'none', 'marker-end' => 'none') {
                xml.path(d: subpath.d, id: "path_#{i*j+i}")
              }
            end
          end
        }
      end

      File.open(file_name, 'w') { |f| f.write builder.to_xml }
      print "Saved to #{file_name}\n"
    end
  end
end