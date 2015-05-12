class TPath
  attr_accessor :tpath

  def initialize(path, width)
    @tpath = Path.new
    path.directions.each do |direction|
      tdirection = direction.clone
      tdirection.start = point_transform(direction.start, width)
      tdirection.finish = point_transform(direction.finish, width)
      begin
        tdirection.rate = tdirection.length / direction.length
      rescue => e
        pp tdirection
        p e.message
        pp e.backtrace[0..4]
      end
      @tpath.directions << tdirection
    end

    calculate_angles
    @tpath
  end

  private
  def calculate_angles
    @tpath.directions.each do |direction|
      dx = direction.finish.x - direction.start.x
      dy = -(direction.finish.y - direction.start.y) # Y axis inverted on the screen and .svg files

      if dy != 0
        tg = dx / dy
      else
        tg = (dx >= 0) ? Float::INFINITY : -Float::INFINITY
      end
      direction.angle = (Math.atan(tg) * 180 / Math::PI).round(2)
    end
  end


  def point_transform(point, w)
    x = point.x
    y = point.y
    lx = Math.sqrt(x*x + y*y)

    x = point.x
    y = point.y
    ly = Math.sqrt((w-x)*(w-x) + y*y)

    Point.new lx.round(2), ly.round(2)
  end

end