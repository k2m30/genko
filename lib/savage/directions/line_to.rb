module Savage
  module Directions
    class LineTo < PointTarget


      def command_code
        (absolute?) ? 'L' : 'l'
      end

      def transform(scale_x, skew_x, skew_y, scale_y, tx, ty)
        # relative line_to dont't need to be tranlated
        tx = ty = 0 if relative?
        transform_dot(target, scale_x, skew_x, skew_y, scale_y, tx, ty)
      end

      def length
        Math.sqrt((position.x-target.x)*(position.x-target.x)+(position.y-target.y)*(position.y-target.y))
      end

      def split(size)
        n = (self.length / (size+1)).ceil
        dx = (target.x-position.x)/n
        dy = (target.y-position.y)/n

        result = []
        n.times do |i|
          result << Savage::Directions::LineTo.new(position.x + dx*(i+1), position.y + dy*(i+1))
        end
        result
      end
    end
  end
end