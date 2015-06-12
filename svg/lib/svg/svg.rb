require 'nokogiri'
require 'yaml'
require_relative 'path/path'
require_relative '../gcode'

class SVG
  attr_accessor :paths, :splitted_paths, :tpaths, :properties
  attr_reader :width, :height, :start_point

  def initialize #(file_name, properties_file_name = 'properties.yml')
    @splitted_paths = []
    @tpaths = []
  end

# @return [It saves paths to .svg separated with move_to lines to illustrate order of painting. Returns nothing]
  def save(file_name, paths)
    dimensions = calculate_dimensions(paths)
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
              width: @properties['canvas_size_x'], height: @properties['canvas_size_y'],
              viewBox: "0, 0, #{@properties['canvas_size_x']}, #{@properties['canvas_size_y']}") {
        xml.marker(id: 'arrow-end',
                   markerWidth: 8, markerHeight: 8,
                   refX: '2%', refY: 4,
                   markerUnits: 'userSpaceOnUse', orient: 'auto') {
          xml.polyline(points: '0,0 8,4 0,8 2,4 0,0',
                       'stroke-width' => 1, stroke: 'darkred', fill: 'red')
        }
        xml.style 'path, rect {stroke-width: 2; fill: none;}'
        xml.style '.stroke {stroke: black;}'
        xml.style '.move_to {stroke: red; marker-end: url(#arrow-end);}'
        xml.style 'path:hover {stroke-width: 4;}'
        xml.style 'text {font-family: Verdana; font-size: 16;}'

        xml.text_(x: '25', y: '15') {
          xml << "Рисование: #{@properties['g01']}мм. Холостой ход: #{@properties['g00']}мм."
        }

        xml.rect(x: 2, y: 2, width: @properties['canvas_size_x']-2, height: @properties['canvas_size_y']-2, stroke: 'grey')
        xml.rect(x: @properties['move_x'], y: @properties['move_y'], width: @properties['width']+2, height: @properties['height']+2, stroke: 'grey')
        xml.rect(x: @properties['crop_x'] + @properties['move_x'],
                 y: @properties['crop_y'] + @properties['move_y'],
                 width: @properties['crop_w'],
                 height: @properties['crop_h'], stroke: 'grey')
        radius = @properties['width'].to_f/100
        radius = 25 if radius > 25
        radius = 5 if radius < 5
        xml.circle(cx: @properties['move_x'], cy: @properties['move_y'], r: radius, fill: 'green')

        #first move_to line
        finish = paths.first.directions.first.finish
        @start_point ||= Point.new @properties['initial_x'], @properties['initial_y']
        d_start = @start_point.to_decart(@properties['canvas_size_x'])
        xml.circle(cx: d_start.x, cy: d_start.y, r: radius, fill: 'green')

        xml.path(id: "move_0", d: "M #{d_start.x},#{d_start.y} L #{finish.x}, #{finish.y} ", class: 'move_to')

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
        finish = d_start
        xml.path(id: "move_#{paths.size}", d: "M #{start.x},#{start.y} L #{finish.x}, #{finish.y} ", class: 'move_to')
      }
    end

    File.open(file_name, 'w') { |f| f.write builder.to_xml }
    print "Saved to #{file_name}\n"
  end

# @return [It saves paths to .svg as is. Returns nothing]
  def dump(file_name, paths)
    dimensions = calculate_dimensions(paths)
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
        xml.style 'path {stroke-width: 2; fill: none;}'
        xml.style '.stroke {stroke: black;}'
        xml.style 'path:hover {stroke-width: 4;}'
        paths.each_index do |i|
          xml.path(d: paths[i].d, id: "path_#{i}", class: 'stroke')
        end
      }
    end

    File.open(file_name, 'w') { |f| f.write builder.to_xml }
    print "Saved to #{file_name}\n"
  end

  def save_html(file_name)
    file_name.sub!('result', 'html')
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head(lang: 'en') {
          doc.meta(charset: 'utf-8')
          doc.script(src: 'js/paint.js')
        }
        doc.body {
          doc.object(data: "../result/#{file_name.sub('./svg/html/', '')}.svg", type: 'image/svg+xml', id: 'result')
          doc.div(style: 'margin: 20px 40% 20px 40%;') {
            doc.button(style: 'width: 100%; height: 60px;', autofocus: 'true', onclick: "paint('result')") {
              doc << 'Paint'
            }
          }
        }
      }
    end


    File.open(file_name + '.html', 'w') { |f| f.write builder.to_html }
    print "Saved to #{file_name}.html\n"
  end

# @return [it splits path into several separate paths according to properties['max_spray_length'] value.
# One path of 100m long can be splitted into 5 of 20m.
# Returns array of paths]
  def split_for_spray
    tmp_length = 0
    tmp_paths = []
    paths = []
    @splitted_paths.each do |path|
      tmp_length+= path.length
      tmp_paths << path
      if tmp_length > @properties['max_spray_length']
        tmp_paths.delete path
        paths << tmp_paths
        tmp_paths = [path]
        tmp_length = path.length
      end
    end
    paths << tmp_paths
    paths
  end

  def save_gcode(file_name, paths)
    gcode_file = GCode.new file_name
    gcode_file.save paths, @properties
  end

  def optimize
    point = @start_point.to_decart @properties['canvas_size_x']
    optimized_paths = []

    until @paths.empty? do
      closest, reversed = find_closest(point, @paths)
      @paths.delete closest
      reversed ? optimized_paths << closest.reversed : optimized_paths << closest
      point = optimized_paths.last.directions.last.finish
    end

    @paths = optimized_paths
  end

  def read_svg(file_name)
    @properties['file_name'] = file_name
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
  end

  def make_tpath
    @splitted_paths.each do |path|
      @tpaths << TPath.new(path, @properties['canvas_size_x']).tpath
    end
  end

  def read_properties(file_name)
    @properties = File.open(file_name) { |f| YAML::load(f) }
    @start_point = Point.new @properties['initial_x'], @properties['initial_y']
  end

  def split
    @paths.each do |path|
      @splitted_paths << path.split(@properties['max_segment_length'])
    end
  end

  def calculate_length
    g00 = length @start_point, @splitted_paths.first.directions.first.finish
    g01 = 0
    @splitted_paths.each_with_index do |path, i|
      if i < @splitted_paths.size - 1
        g00 += length @splitted_paths[i].directions.last.finish, @splitted_paths[i+1].directions.first.finish
      end
      g01 += path.length
    end

    g00 += length @splitted_paths.last.directions.last.finish, @start_point
    @properties['g00'] = g00
    @properties['g01'] = g01
  end

  def move
    dx = @properties['move_x']
    dy = @properties['move_y']

    if dx.nil? || dy.nil?
      p 'No move parameters found. Continue without move'
      return
    end

    @splitted_paths.each_index do |i|
      @splitted_paths[i].directions.each do |direction|
        direction.start.x += dx
        direction.start.y += dy

        direction.finish.x += dx
        direction.finish.y += dy
      end
    end
  end

  def crop
    x0 = @properties['crop_x']
    y0 = @properties['crop_y']
    w = @properties['crop_w']
    h = @properties['crop_h']
    if x0.nil? || y0.nil? || w.nil? || h.nil?
      p 'No crop parameters found. Continue without crop'
      return
    end
    @splitted_paths.each_with_index do |path, i|
      path.directions.each_with_index do |d, k|
        if (d.is_a? LineTo)&&
            (d.start.x < x0 ||
                d.start.y < y0 ||
                d.finish.x > x0 + w ||
                d.finish.y > y0 + h)
          next_path = Path.new
          next_path.directions.push MoveTo.new('M', [d.finish.x, d.finish.y])
          next_path.directions.first.start = next_path.directions.first.finish.dup
          next_path.directions += path.directions.drop k+1
          @splitted_paths.insert i+1, next_path
          @splitted_paths[i].directions = path.directions.take k
          break
        end
      end
    end

    to_delete = []
    @splitted_paths.each_with_index do |path, i|
      if path.directions.size <= 1 || path.directions.all? { |d| d.is_a? MoveTo }
        to_delete << path
      end
    end

    to_delete.each do |path|
      @splitted_paths.delete(path)
    end
  end

  private

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

  def find_closest(point, paths)
    closest_distance = Float::INFINITY
    closest_path = nil
    to_reverse = false

    paths.each do |path|
      start_point = path.directions.first.finish
      finish_point = path.directions.last.finish
      distance_to_start = Math.sqrt((start_point.x-point.x)**2 + (start_point.y-point.y)**2)
      distance_to_finish = Math.sqrt((finish_point.x-point.x)**2 + (finish_point.y-point.y)**2)

      if (distance_to_start < closest_distance) && (distance_to_start <= distance_to_finish)
        closest_path = path
        closest_distance = distance_to_start
        to_reverse = false
      end

      if (distance_to_finish < closest_distance) && (distance_to_finish < distance_to_start)
        closest_path = path
        closest_distance = distance_to_finish
        to_reverse = true
      end

    end
    return closest_path, to_reverse
  end

  def length(p1, p2)
    Math.sqrt((p1.x-p2.x)**2+(p1.y-p2.y)**2).round
  end

end