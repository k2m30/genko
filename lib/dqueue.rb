class DQueue
  def initialize
    @queue = []
    @index = 0
  end

  def size
    @queue.size
  end

  def last
    @queue.last
  end

  def first
    @queue.first
  end

  def << (el)
    @queue << el
  end
  alias + <<

  def current
    @queue[@index]
  end

  def next
    @index == size ? current : @queue[@index+1]
  end

  def prev
    @index > 0 ? @queue[@index+1] : current
  end

  def [](i)
    @queue[i]
  end

  def each(*args, &block)
    if block_given?
      yield args, &block
    end
  end

end