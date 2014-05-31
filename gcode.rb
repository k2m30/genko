require "nokogiri"
require "savage"
require "yaml"
require_relative "svg"

module Savage
  class SubPath
    def to_command
      @directions.to_enum(:each_with_index).collect { |dir, i|
        command_string = dir.to_command      
      }.join
    end
  end
end

class SVGFile
  attr_reader :paths, :elements, :properties, :whole_path, :width, :height

  def initialize(file_name)
    @allowed_elements = ['path']
    @paths = []
    @whole_path = []
    @elements = []
    @properties = {}
    read_svg file_name
    read_properties
    read_whole_path
  end

  def read_svg(file_name)
    svg = Nokogiri::XML File.open file_name
    svg.traverse do |e|
      @elements.push e if e.element? &&  @allowed_elements.include?(e.name)
    end
    @elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map!{ |path| Savage::Parser.parse path}
    p paths[3].to_command
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end
  def read_properties
    @properties = File.open("properties.yml") { |yf| YAML::load(yf) }
  end
  def read_whole_path
    @paths.each do |path|
      path.subpaths.each do |subpath|
        subpath.directions.each do |direction|
          @whole_path.push direction
        end
      end
    end
  end
  def save(file_name, paths)
    output_file = SVG.new(@width, @height)
    paths.each { |path| output_file.svg << output_file.path(path.to_command) }
    output_file.save(file_name)
  end
end

file_name = ARGV[0] || Dir.pwd + '/rack.svg'

svg_file = SVGFile.new file_name
paths = svg_file.paths


svg_file.save 'output.svg', svg_file.paths
# p svg_file.properties
# p svg_file.paths[3].to_command
