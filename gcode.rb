require 'pp'

require_relative 'lib/svg'
require_relative 'lib/savage'
require_relative 'lib/svg_file'

file_name = ARGV[0] || Dir.pwd + '/images' + '/risovaka007_003.svg'
# file_name = ARGV[0] || 'http://openclipart.org/people/rastrojo2/1360514599.svg'

svg_file = SVGFile.new file_name


# x,y = 900,300
#
# point = Savage::Directions::Point.new x, y
# tpoint = svg_file.point_transform(point)
# belt_x = tpoint.x
# belt_y = tpoint.y
#
# gpoint = svg_file.point_to_triangle(x,y)
# pp "G00 X#{gpoint[0]} Y#{gpoint[1]} Z0"
# pp ['Belts: ',belt_x, belt_y]
# pp ['x, y :',svg_file.tpoint_to_decart(belt_x-1000, belt_y-1000)]

tpath = svg_file.tpath

svg_file.save 'simplified.svg', [svg_file.whole_path]
svg_file.save 'result.svg', [tpath]
svg_file.make_gcode_file
