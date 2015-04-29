class VerticalTo < LineTo
  def initialize(command_code, coordinates)
    @command_code = command_code
    @coordinates = coordinates
    @finish = Point.new nil, coordinates[-1]
  end

  def absolute!(start_point=nil)
    unless absolute?
      @finish.y += start_point.y
      @command_code.upcase!
    end
    @start = start_point
    @finish.x = start_point.x
    self
  end
end