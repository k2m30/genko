module Savage
  class Path
    require File.dirname(__FILE__) + "/direction_proxy"
    require File.dirname(__FILE__) + "/sub_path"

    include Utils
    include DirectionProxy
    include Transformable

    attr_accessor :subpaths

    define_proxies do |sym, const|
      define_method(sym) do |*args|
        @subpaths.last.send(sym, *args)
      end
    end

    def clone
      Marshal::load(Marshal.dump(self))
    end

    def absolute!
      x = y = 0
      start_point = end_point = nil
      @subpaths.each do |subpath|
        subpath.directions.each_with_index do |direction, i|
          next if direction.kind_of? Savage::Directions::ClosePath
          if direction.target.kind_of?(Savage::Directions::Point)
            x = direction.target.x
            y = direction.target.y
          end

          end_point = direction.target
          case direction.command_code
            when 'H', 'h'
              x = direction.target
              y = 0 unless direction.absolute?
              end_point = Savage::Directions::Point.new(x, y)
              direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
            when 'V', 'v'
              x = 0 unless direction.absolute?
              y = direction.target
              end_point = Savage::Directions::Point.new(x, y)
              direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
            when 'L', 'l', 'M', 'm'
            when 'C'
            when 'c'
              direction.control.x += start_point.x
              direction.control.y += start_point.y

              direction.control_1.x += start_point.x
              direction.control_1.y += start_point.y

            when 'S'
            when 's'
              direction.control.x += start_point.x
              direction.control.y += start_point.y
            when 'Q'
            when 'q'
              direction.control.x += start_point.x
              direction.control.y += start_point.y
            else
              raise ArgumentError, "Unknown element: #{direction.command_code}, #{direction}"
          end
          end_point = direction.target
          if direction.relative?
            begin
              x += start_point.x
              y += start_point.y

              end_point = Savage::Directions::Point.new(x, y)
              direction.absolute = true
              direction.target = end_point
            rescue => e
              p e.message
              p e.backtrace[0..2]
            end #rescue
          end #unless
          subpath.directions[i] = direction
          start_point = end_point
        end #each
      end #each
    end

    #absolute

    def initialize(*args)
      @subpaths = [SubPath.new]
      @subpaths.last.move_to(*args) if (2..3).include?(*args.length)
      yield self if block_given?
    end

    def directions
      directions = []
      @subpaths.each { |subpath| directions.concat(subpath.directions) }
      directions
    end

    def calculate_start_points!(initial_x = 0, initial_y = 0)
      directions.first.position = Savage::Directions::Point.new initial_x, initial_y
      directions.each_with_index do |direction, i|
        next_direction = directions[i+1]
        break if next_direction.nil?
        next_direction.position = direction.target
      end
    end

    def length
      length_g00 = 0
      length_g01 = 0
      directions.each do |direction|
        length_g00 += direction.length/direction.rate if direction.kind_of? Savage::Directions::MoveTo
        length_g01 += direction.length/direction.rate if direction.kind_of? Savage::Directions::LineTo
      end
      {length_g00: length_g00, length_g01: length_g01}
    end

    def calculate_angles!
      directions.each do |direction|
        dx = direction.target.x - direction.position.x
        dy = -(direction.target.y - direction.position.y) # Y axis inverted on the screen and .svg files

        if dy != 0
          tg = dx / dy
        else
          tg = (dx >= 0) ? Float::INFINITY : -Float::INFINITY
        end
        direction.angle = to_deg(Math.atan(tg))
      end
    end

    def move_to(*args)
      unless (@subpaths.last.directions.empty?)
        (@subpaths << SubPath.new(*args)).last
      else
        @subpaths.last.move_to(*args)
      end
    end

    def closed?
      @subpaths.last.closed?
    end

    def to_command
      @subpaths.collect { |subpath| subpath.to_command }.join
    end

    def transform(*args)
      dup.tap do |path|
        path.to_transformable_commands!
        path.subpaths.each { |subpath| subpath.transform *args }
      end
    end

    # Public: make commands within transformable commands
    #         H/h/V/v is considered not 'transformable'
    #         because when they are rotated, they will
    #         turn into other commands
    def to_transformable_commands!
      subpaths.each &:to_transformable_commands!
    end

    def fully_transformable?
      subpaths.all? &:fully_transformable?
    end

    private
    def to_deg(angle)
      angle * 180 / Math::PI
    end

  end
end
