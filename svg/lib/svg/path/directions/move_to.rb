class MoveTo < Direction
  def split(size)
    [self]
  end
  def length
    1
  end
end