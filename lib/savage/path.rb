module Savage
  class Path
    require File.dirname(__FILE__) + "/direction_proxy"
    require File.dirname(__FILE__) + "/sub_path"

    include Utils
    include DirectionProxy
    include Transformable

    attr_accessor :subpaths

    define_proxies do |sym,const|
      define_method(sym) do |*args|
        @subpaths.last.send(sym,*args)
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
          unless end_point.kind_of? Savage::Directions::Point
            case direction.class.to_s
              when 'Savage::Directions::HorizontalTo'
                x = direction.target
                y  = 0 unless direction.absolute?
                end_point = Savage::Directions::Point.new(x,y)
                direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
              when 'Savage::Directions::VerticalTo'
                x = 0 unless direction.absolute?
                y = direction.target
                end_point = Savage::Directions::Point.new(x,y)
                direction = Savage::Directions::LineTo.new(end_point.x, end_point.y, direction.absolute?)
              else
                raise ArgumentError, "Unknown element: #{direction.class}"
            end #case
          end #unless
          end_point = direction.target
          if direction.relative?
            begin
              x += start_point.x
              y += start_point.y
              end_point = Savage::Directions::Point.new(x,y)
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
    end #absolute

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
        path.subpaths.each {|subpath| subpath.transform *args }
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

  end
end
