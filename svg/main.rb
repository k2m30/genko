require 'pp'

require_relative 'lib/tpath'
require_relative 'lib/svg/svg'

COLORS = %w[red yellow green white black grey blue]

def include_color?(value)
  COLORS.map { |color| value.include? color }.any?
end

def split_colors(file_name)
  layers = []
  svg = Nokogiri::XML::Document.parse open file_name

  @width = svg.at_css('svg')[:width].to_f
  @height = svg.at_css('svg')[:height].to_f
  p [file_name, @width, @height]

  svg.root.elements.select { |e| e.attributes['id'] && include_color?(e.attributes['id'].value) }.each do |layer|
    name = layer.attributes['id'].value
    builder = Nokogiri::XML::Builder.new do
      doc.create_internal_subset('svg', '-//W3C//DTD SVG 1.1//EN', 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd')
      svg('version' => '1.1', 'xmlns' => 'http://www.w3.org/2000/svg', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink') {
        parent << layer.to_xml
      }
    end

    File.open("#{name}.svg", 'w+') do |f|
      f.write builder.to_xml
      layers << f.path
    end
  end
  layers
end

def split_for_spray(file_name, properties_file_name = 'properties.yml')
  svg_file = SVG.new
  svg_file.read_properties properties_file_name
  svg_file.read_svg file_name

  # svg_file.optimize
  svg_file.split
  svg_file.crop
  svg_file.move


  paths_set = svg_file.split_for_spray
  names = []
  paths_set.each_with_index do |paths, i|
    name = file_name.gsub('.svg', "_#{i}.svg")
    names.push  name
    svg_file.dump(name, paths)
  end
  names
end

# file_name = ARGV[0] || Dir.pwd + '/images/hare_1775.svg'
# file_name = ARGV[0] || Dir.pwd + '/images/Domik.svg'
# file_name = ARGV[0] || Dir.pwd + '/images/fill.svg'
# file_name = ARGV[0] || Dir.pwd + '/images/yellow.svg'
file_name = ARGV[0] || './svg/images/risovaka007_003.svg'
color_files = split_colors(file_name)

p color_files

Dir.mkdir('svg/result') unless Dir.exists?('svg/result')

properties_file_name = './svg/properties.yml'
tmp_files_splitted = []

color_files.each_with_index do |tmp_name, i|
  names = split_for_spray tmp_name, properties_file_name

  names.each do |name|
    svg_file = SVG.new
    svg_file.read_properties properties_file_name
    svg_file.properties['width'] = @width
    svg_file.properties['height'] = @height
    svg_file.read_svg name

    next if svg_file.paths.empty?
    svg_file.splitted_paths = svg_file.paths
    svg_file.calculate_length
    svg_file.make_tpath

    new_name = "./svg/result/0#{i.next}_#{name.gsub('.svg', '')}"
    svg_file.save("#{new_name}_splitted.svg", svg_file.splitted_paths)
    svg_file.save_html("#{new_name}_splitted")
    svg_file.save("#{new_name}_result.svg", svg_file.tpaths)
    svg_file.save_gcode("#{new_name}.gcode", svg_file.tpaths)

    g = GCode.new "#{new_name}.gcode"
    g.to_svg
  end
  tmp_files_splitted += names
end

color_files.each { |file| File.delete file }

tmp_files_splitted.each { |file| File.delete file }
