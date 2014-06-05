module Savage
  module Directions
    class LineTo < PointTarget
      attr_accessor :rate

      def command_code
        (absolute?) ? 'L' : 'l'
      end

      def transform(scale_x, skew_x, skew_y, scale_y, tx, ty)
        # relative line_to dont't need to be tranlated
        tx = ty = 0 if relative?
        transform_dot(target, scale_x, skew_x, skew_y, scale_y, tx, ty)
      end

      def length(start_point)
        Math.sqrt((start_point.x-target.x)*(start_point.x-target.x)+(start_point.y-target.y)*(start_point.y-target.y))
      end

      def split(start_point, size)
        n = (self.length(start_point) / (size+1)).ceil
        dx = (target.x-start_point.x)/n
        dy = (target.y-start_point.y)/n

        result = []
        n.times do |i|
          result << Savage::Directions::LineTo.new(start_point.x + dx*(i+1), start_point.y + dy*(i+1))
        end
        result
      end
    end
  end
end
