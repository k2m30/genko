module Savage
  module Directions
    class MoveTo < PointTarget
      def command_code
        (absolute?) ? 'M' : 'm'
      end

      def transform(scale_x, skew_x, skew_y, scale_y, tx, ty)
        # relative move_to dont't need to be tranlated
        tx = ty = 0 if relative?
        transform_dot( target, scale_x, skew_x, skew_y, scale_y, tx, ty )
      end
      def split(size)
        [self]
      end

      def length
        Math.sqrt((position.x-target.x)*(position.x-target.x)+(position.y-target.y)*(position.y-target.y))
      end

    end
  end
end
