module Savage
  module Directions
    class QuadraticCurveTo < PointTarget
      attr_accessor :control

      def initialize(*args)
        raise ArgumentError if args.length < 2
        case args.length
          when 2
            super(args[0], args[1], true)
          when 3
            raise ArgumentError if args[2].kind_of?(Numeric)
            super(args[0], args[1], args[2])
          when 4
            @control = Point.new(args[0], args[1])
            super(args[2], args[3], true)
          when 5
            @control = Point.new(args[0], args[1])
            super(args[2], args[3], args[4])
        end
      end

      def split(size, last_curve_point=nil)
        n = 4

        x0 = position.x
        y0 = position.y

        if @control
          x1 = @control.x
          y1 = @control.y
        else
          p position
          p last_curve_point
          x1 = 2 * position.x - last_curve_point.x
          y1 = 2 * position.y - last_curve_point.y
        end

        x2 = target.x
        y2 = target.y

        #if curve is too small - just change it to line
        if (length(x0, y0, x1, y1) < size/n) && (length(x1, y1, x2, y2) < size/n) &&
            (length(x0, y0, x2, y2) < size/n)
          return [Savage::Directions::LineTo.new(x2, y2)]
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
            x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
            y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
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
          x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
          y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
          result << Savage::Directions::LineTo.new(x, y)
          t+=dt
        end
        t = 1
        x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
        y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
        result << Savage::Directions::LineTo.new(x, y)

      end

      def to_a
        if @control
          [command_code, @control.x, @control.y, @target.x, @target.y]
        else
          [command_code, @target.x, @target.y]
        end
      end

      def command_code
        return (absolute?) ? 'Q' : 'q' if @control
        (absolute?) ? 'T' : 't'
      end

      def transform(scale_x, skew_x, skew_y, scale_y, tx, ty)
        # relative line_to dont't need to be tranlated
        tx = ty = 0 if relative?
        transform_dot(target, scale_x, skew_x, skew_y, scale_y, tx, ty)
        transform_dot(control, scale_x, skew_x, skew_y, scale_y, tx, ty) if control
      end
    end
  end
end
