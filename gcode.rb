require "nokogiri"
require "savage"

class SVGFile
  attr_reader :paths
  def initialize(file_name)
    @paths = []
    allowed_elements = ['path']
    svg = Nokogiri::XML File.open file_name
    elements = []
    svg.traverse do |e|
      elements.push e if e.element? &&  allowed_elements.include?(e.name)
    end
    elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map!{ |path| Savage::Parser.parse path}
  end

end

filename = ARGV[0] || Dir.pwd + '/rack.svg'

svg_file = SVGFile.new filename
paths = svg_file.paths

paths.each do |path|
  path.subpaths.each do |subpath|
    subpath.directions.each do |direction|
      p direction.class
    end
  end
end
