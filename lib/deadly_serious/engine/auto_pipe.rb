class DeadlySerious::Engine::AutoPipe
  TEMPLATE = 'pipe.%s'

  class Counter
    TEMPLATE = '%04d'

    def initialize
      @counter = 0
    end

    def next
      @counter += 1
      last
    end

    def last
      format(TEMPLATE, @counter)
    end

    def zero?
      @counter == 0
    end
  end

  def initialize
    @counters = [Counter.new]
  end

  def next
    current_counter.next
    last
  end

  def last
    return nil if current_counter.zero?
    format(TEMPLATE, @counters.map(&:last).join('.'))
  end

  def on_subnet
    @counters << Counter.new
    yield
  ensure
    @counters.pop
  end

  private

  def current_counter
    @counters.last
  end
end
