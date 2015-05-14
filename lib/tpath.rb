class TPath
  attr_accessor :tpath

  def initialize(path, width)
    @tpath = Path.new
    path.directions.each do |direction|
      tdirection = direction.clone
      tdirection.start = direction.start.t_transform width
      tdirection.finish = direction.finish.t_transform width
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

end