class HorizontalTo < LineTo
  def initialize(command_code, coordinates)
    @command_code = command_code
    @coordinates = coordinates
    @finish = Point.new coordinates[-1], nil
  end

  def absolute!(start_point=nil)
    unless absolute?
      @finish.x += start_point.x
      command_code.upcase!
    end
    @finish.y = start_point.y
    @start = start_point
    self
  end
end