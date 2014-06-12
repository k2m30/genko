require 'pp'

require_relative 'lib/svg'
require_relative 'lib/savage'
require_relative 'lib/svg_file'

#file_name = ARGV[0] || Dir.pwd + '/Domik.svg'
#file_name = ARGV[0] || Dir.pwd + '/rack.svg'
file_name = ARGV[0] || Dir.pwd + '/images' + '/calibrate.svg'
#file_name = 'http://openclipart.org/people/mazeo/rabbit.svg'

svg_file = SVGFile.new file_name
tpath = svg_file.tpath

svg_file.save 'simplified.svg', [svg_file.whole_path]
svg_file.save 'result.svg', [tpath]
svg_file.make_gcode_file
