module DeadlySerious
  class Listener
    def initialize(buffer_size: 4096)
      @selector = NIO::Selector.new
      @monitors = []
      @buffer = ''
      @buffer_size = buffer_size
    end

    def on_receive_from(input_io, &block)
      monitor = @selector.register(input_io, :r)
      monitor.value = -> do
        begin
          handle_input(monitor.io.read_nonblock(@buffer_size), block)
        rescue EOFError
          throw :closed, input_io
        end
      end
      @monitors << monitor
    end

    def listen
      catch :halt do
        loop do
          io = catch :closed do
            loop { @selector.select { |m| m.value.call } }
          end
          io.close if io && !io.closed?
          @selector.deregister(io) if io
          throw :halt if @selector.empty?
        end
      end
    ensure
      @selector.close
    end

    private

    def handle_input(input, block)
      @buffer << input
      while match = @buffer.match(/[^\n]+\n/)
        block.call match.to_s.chomp
        @buffer = match.post_match
      end
    end
  end
end