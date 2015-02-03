module Savage
  class SubPath
    include Utils
    include DirectionProxy
    include Transformable

    define_proxies do |sym, const|
      define_method(sym) do |*args|
        raise TypeError if const == "QuadraticCurveTo" && @directions.last.class != Directions::QuadraticCurveTo && [2, 3].include?(args.length)
        raise TypeError if const == "CubicCurveTo" && @directions.last.class != Directions::CubicCurveTo && [4, 5].include?(args.length)
        (@directions << Savage::Directions.const_get(const).new(*args)).last
      end
    end

    attr_accessor :directions

    def move_to(*args)
      return nil unless @directions.empty?
      (@directions << Directions::MoveTo.new(*args)).last
    end

    def initialize(*args)
      @directions = []
      move_to(*args) if (2..3).include?(args.length)
      yield self if block_given?
    end

    def to_command
      @directions.to_enum(:each_with_index).collect { |dir|
        dir.to_command
      }.join(' ')
    end

    def commands
      @directions
    end

    def closed?
      @directions.last.kind_of? Directions::ClosePath
    end

    def transform(*args)
      directions.each { |dir| dir.transform *args }
    end

    def to_transformable_commands!
      if !fully_transformable?
        pen_x, pen_y = 0, 0
        directions.each_with_index do |dir, index|
          unless dir.fully_transformable?
            directions[index] = dir.to_fully_transformable_dir(pen_x, pen_y)
          end

          dx, dy = dir.movement
          if dir.absolute?
            pen_x = dx if dx
            pen_y = dy if dy
          else
            pen_x += dx if dx
            pen_y += dy if dy
          end
        end
      end
    end

    def fully_transformable?
      directions.all? &:fully_transformable?
    end
  end
end
