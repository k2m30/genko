class ClosePath < Direction

  def absolute!(start_point=nil)
    command_code.upcase!
    self
  end

  def to_command
    ' Z'
  end

  def split(size)
    [self]
  end

end