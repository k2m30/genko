class CubicCurveTo < QuadraticCurveTo
  attr_accessor :control_point_2

  def initialize(command_code, coordinates)
    if command_code.downcase == 'c'
      @control_point_2 = Point.new coordinates[2], coordinates[3]
    elsif command_code.downcase == 's'
      @control_point_2 = nil
    end
    super
  end


  def split(size, last_curve_point=nil)
    n = 4 #start number of pieces value

    x0 = @start.x
    y0 = @start.y

    if @control_point_2
      x1 = @control_point_1.x
      y1 = @control_point_1.y
    else
      x1 = 2 * @start.x - last_curve_point.x
      y1 = 2 * @start.y - last_curve_point.y
    end

    x2 = @control_point_2.x
    y2 = @control_point_2.y

    x3 = @finish.x
    y3 = @finish.y

    #if curve is too small - just change it to line
    if (length(x0, y0, x1, y1) < size) && (length(x1, y1, x2, y2) < size) &&
        (length(x2, y2, x3, y3) < size) && (length(x0, y0, x3, y3) < size)
      return [LineTo.new('L', [x3.round(2), y3.round(2)])]
    end

    #### detecting proper differentiation value
    max_length = nil

    begin
      last_x = x0
      last_y = y0
      max_length = 0
      n=(n*1.2).round
      dt = 1.0/n
      t = dt

      n.times do
        x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
        y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
        length = Math.sqrt((x-last_x)*(x-last_x)+(y-last_y)*(y-last_y))
        max_length = length if length > max_length
        t+=dt
        last_x = x
        last_y = y
      end
    end while max_length > size

    ####
    dt = 1.0/n
    t = dt

    result = []
    (n-1).times do
      x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
      y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
      result << LineTo.new('L', [x.round(2), y.round(2)])
      t+=dt
    end
    t = 1
    x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
    y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
    result << LineTo.new('L', [x.round(2), y.round(2)])
    result
  end

  def to_command
    " #{command_code} #{@control_point_1.x} #{@control_point_1.y} #{@control_point_2.x} #{@control_point_2.y} #{finish.x} #{finish.y}"
  end

  def absolute!(start_point=nil)
    unless absolute?
      @control_point_2.x += start_point.x
      @control_point_2.y += start_point.y
    end
    super
  end


end