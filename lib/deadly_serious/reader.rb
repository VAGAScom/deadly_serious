module DeadlySerious
  class Reader
    def initialize(io, buffer_size: 4096)
      @io = io
      @buffer_size = buffer_size
      @buffer = ''
    end

    def readline
      handle_receiving
    end

    private

    def handle_receiving
      @buffer << @io.read_nonblock(@buffer_size)
      parse_buffer
    rescue IO::WaitReadable
      # Nothing to read
      parse_buffer
    rescue EOFError, Errno::ECONNRESET
      @io.close if @io && !@io.closed?
      throw :io_closed
    end

    def parse_buffer
      match = @buffer.match(/[^\n]+\n/)
      return unless match

      @buffer = match.post_match
      match.to_s.chomp
    end
  end
end