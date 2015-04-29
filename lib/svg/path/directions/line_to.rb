class LineTo < Direction

  def split(size)
    n = (self.length / (size+1)).ceil
    dx = (finish.x-start.x)/n
    dy = (finish.y-start.y)/n

    result = []
    n.times do |i|
      result << LineTo.new('L', [(start.x + dx*(i+1)).round(2), (start.y + dy*(i+1)).round(2)])
    end
    result
  end

end