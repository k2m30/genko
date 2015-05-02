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

  svg_file.optimize
  svg_file.split
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
file_name = ARGV[0] || Dir.pwd + '/images/risovaka007_003.svg'
tmp_files = split_colors(file_name)
p tmp_files

Dir.mkdir('result') unless Dir.exists?('result')

properties_file_name = 'properties.yml'
tmp_files_splitted = []

tmp_files.each_with_index do |tmp_name, i|
  names = split_for_spray tmp_name, properties_file_name

  names.each do |name|
    svg_file = SVG.new
    svg_file.read_properties properties_file_name
    svg_file.read_svg name

    svg_file.splitted_paths = svg_file.paths
    svg_file.calculate_length
    svg_file.make_tpath

    new_name = "./result/0#{i.next}_#{name.gsub('.svg', '')}"
    svg_file.save("#{new_name}_splitted.svg", svg_file.splitted_paths)
    svg_file.save_html("#{new_name}_splitted")
    svg_file.save("#{new_name}_result.svg", svg_file.tpaths)
    svg_file.make_gcode_file("#{new_name}.gcode", svg_file.tpaths)
  end
  tmp_files_splitted += names
end

tmp_files.each do |file|
  File.delete file
end

tmp_files_splitted.each do |file|
  File.delete file
end
