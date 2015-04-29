class MoveTo < Direction
  def split(size)
    [self]
  end
  def length
    nil
  end
end