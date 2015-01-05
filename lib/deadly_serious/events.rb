module DeadlySerious
  class Events
    EMPTY = []

    def initialize
      @events = Hash.new { |h, k| h[k] = [] }
      yield self if block_given?
    end

    def when(event_name, &block)
      @events[event_name.to_sym] << block
    end

    def execute(event_name, ** args)
      @events.fetch(event_name.to_sym, EMPTY).each do |event|
        event.call(** args)
      end
    end
  end
end