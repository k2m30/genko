require 'pp'

require_relative 'lib/svg'
require_relative 'lib/savage'
require_relative 'lib/svg_file'

COLORS = %w[red yellow green white black grey blue]

def include_color?(value)
  # require 'pry'; binding.pry
  COLORS.map { |color| value.include? color }.any?
end

def split_colors(file_name)
  layers = []
  svg = Nokogiri::XML::Document.parse(open(file_name))

  svg.root.elements.select { |e| e.attributes["id"] && include_color?(e.attributes["id"].value) }.each do |layer|

    name = layer.attributes["id"].value

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

# file_name = ARGV[0] || Dir.pwd + '/images/car.svg'
file_name = ARGV[0] || Dir.pwd + '/images/Domik.svg'
tmp_files = split_colors(file_name)
p tmp_files

Dir.mkdir('result') unless Dir.exists?('result')

tmp_files.each_with_index do |name, i|
  svg_file = SVGFile.new(name)
  new_name = "./result/0#{i.next}_#{name.gsub('.svg', '')}"

  svg_file.save("#{new_name}_splitted.svg", [svg_file.splitted_path])

  # svg_file.save("#{new_name}_simplified.svg", [svg_file.arris_highlighted_path])

  svg_file.save("#{new_name}_result.svg", [svg_file.tpath])
  svg_file.make_gcode_file("#{new_name + '.gcode'}")
end

tmp_files.each do |file|
  File.delete file
end
