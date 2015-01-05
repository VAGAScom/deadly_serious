module DeadlySerious
  class Writer
    def initialize(io)
      @io = io
      @buffer = ''
    end

    def puts(string)
      print("#{string}\n")
    end

    def print(string)
      @buffer << string.to_str
      handle_sending
    end

    private

    def handle_sending
      @io.write_nonblock(@buffer)
      @io.flush
      @buffer = ''
    rescue IO::WaitWritable
      # Just do nothing
    rescue EOFError, Errno::ECONNRESET, Errno::EPIPE
      @io.close if @io && !@io.closed?
      throw :io_closed
    end
  end
end