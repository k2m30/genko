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

    # @tpaths.calculate_angles!
    # l = @tpaths.length
    # @properties[:g00] = l[:length_g00]
    # @properties[:g01] = l[:length_g01]
    tpath
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