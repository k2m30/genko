module Savage
  module Directions
    class PointTarget < Direction

      attr_accessor :target, :position, :rate

      def initialize(x, y, absolute=true)
        @target = Point.new(x,y)
        super(absolute)
      end

      def to_a
        [command_code, @target.x, @target.y]
      end

      def movement
        [target.x, target.y]
      end

      def length(x1,y1,x2,y2)
        Math.sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
      end

      def round!(n=2)
        target.x=target.x.round(n)
        target.y=target.y.round(n)
        position.x = position.x.round(n)
        position.y = position.y.round(n)
      end
    end
  end
end
