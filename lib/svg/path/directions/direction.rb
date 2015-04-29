Point = Struct.new :x, :y

class Direction
  attr_accessor :start, :finish, :rate, :angle
  attr_reader :command_code


  def initialize(command_code, coordinates)
    @command_code = command_code
    @coordinates = coordinates
    @finish = Point.new coordinates[-2], coordinates[-1]
  end

  def absolute?
    @command_code == @command_code.upcase
  end

  def length(x1=nil, y1=nil, x2=nil, y2=nil)
      if x1.nil? && x2.nil? && y1.nil? && y2.nil?
        Math.sqrt((@start.x-@finish.x)**2 + (@start.y-@finish.y)**2)
      else
        Math.sqrt((x2-x1)**2 + (y2-y1)**2)
      end
  end

  def absolute!(start_point=nil)
    unless absolute?
      @finish.x += start_point.x
      @finish.y += start_point.y
      command_code.upcase!
    end
    @start = start_point
    self
  end

  def to_command
    " #{command_code} #{finish.x} #{finish.y}"
  end

end