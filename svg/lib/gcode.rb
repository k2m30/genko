require_relative 'svg/path/directions/point'
require_relative 'svg/svg'

class GCode
  def initialize(file_name)
    @file_name = file_name
  end

  def to_svg
    read_properties
    svg = SVG.new
    svg.properties = @properties
    paths = []
    path = nil
    File.open @file_name, 'r' do |f|
      f.readlines.each do |line|
        xy = line.match /G0([01]) X(-?\d+.\d*) Y(-?\d+.\d*)/
        if xy.nil?
        else
          point = Point.new(xy[2].to_f + @properties['initial_x'].to_f, xy[3].to_f + @properties['initial_y'].to_f)
          decart_point = point.to_decart(@properties['canvas_size_x'].to_f)
          case xy[1].to_i
            when 0
              unless path.nil?
                path.organize!
                paths.push path
              end
              path = Path.new
              path.directions.push MoveTo.new 'M', [decart_point.x, decart_point.y]
            when 1
              path.directions.push LineTo.new 'L', [decart_point.x, decart_point.y]
          end
        end
      end
      svg.dump(@file_name+'.check.svg', paths)
    end
  end

  def read_properties
    @properties = Hash.new
    File.open @file_name, 'r' do |f|
      f.readlines.each do |line|
        break if line == '%'
        pair = line.match /\(\["(.*)",(.*)\]\)/
        next if pair.nil?
        begin
          @properties[pair[1]] = pair[2].to_f
        rescue
          @properties[pair[1]] = pair[2]
        end
      end
    end
  end

  def save(paths, properties)
    begin
      f = File.new @file_name, 'w+'
      f.puts "(#{@file_name})"
      f.puts "(#{Time.now.strftime('%d-%b-%y %H:%M:%S').to_s})"
      properties.each_pair { |pair| f.puts "(#{pair})" }
      f.puts '%'
      #f.puts 'G51Y-1'
      initial_x = properties['initial_x']
      initial_y = properties['initial_y']

      paths.each do |path|
        f.puts
        f.puts "(#{path.length} #{path.d})"
        path.directions.each do |direction|
          x = (direction.finish.x - initial_x).round(2)
          y = (direction.finish.y - initial_y).round(2)
          case direction.command_code
            when 'M'
              f.puts 'G00 Z0'
              f.puts "G00 X#{x} Y#{y} Z0"
            when 'L'
              feed = (properties['linear_velocity'] * direction.rate).round(2)
              f.puts "G01 X#{x} Y#{y} Z#{properties['z_turn']} F#{feed}"
            else
              raise ArgumentError "Bad command in tpath #{direction.command_code}"
          end
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
    print "Saved to #{@file_name}\n"
  end
end