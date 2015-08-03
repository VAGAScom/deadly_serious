require 'socket'

module DeadlySerious
  module Engine
    class SocketChannel

      def self.new_if_match(name, _config)
        matcher = name.match(/\A(.*?):(\d{1,5})\z/)
        self.new(matcher[1], matcher[2].to_i) if matcher
      end

      def initialize(host, port)
        @host, @port = host, port
        @retry_counter = 3
      end

      def io_name
        "#{@host}@#{@port}"
      end

      def create
        # Do nothing
      end

      def open_reader
        TCPSocket.new(@host, @port)
      rescue Exception => e
        @retry_counter -= 1
        if @retry_counter > 0
          sleep 1 and retry
        else
          raise e
        end
      end

      def open_writer
        server = TCPServer.new(@port)
        server.accept
      end

      def io
        LazyIo.new(self)
      end
    end
  end
end