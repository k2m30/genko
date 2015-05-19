class GCode
  def initialize(file_name)
    @file_name = file_name
  end

  def to_svg

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