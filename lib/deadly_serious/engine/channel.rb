require 'socket'

module DeadlySerious
  module Engine
    # Fake class, it's actually a factory ¬¬
    module Channel
      def self.new(name, data_dir: nil, pipe_dir: nil)
        matcher = name.match(/^(>)?(.*?)(?:(:)(\d{1,5}))?$/)
        if matcher[1] == '>'
          FileChannel.new(matcher[2], data_dir)
        elsif matcher[3] == ':'
          SocketChannel.new(matcher[2], matcher[4].to_i)
        else
          PipeChannel.new(matcher[2], pipe_dir)
        end
      end
    end

    class FileChannel
      def initialize(name, directory)
        @io_name = File.join(directory, name)
      end

      def create
        `touch #{@io_name}` unless File.exist?(@io_name)
        @io_name
      end

      def open_reader
        fail %(File "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'r')
      end

      def open_writer
        fail %(File "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'w')
      end
    end

    class PipeChannel
      def initialize(name, directory)
        @io_name = File.join(directory, name)
      end

      def create
        `mkfifo #{@io_name}` unless File.exist?(@io_name)
        @io_name
      end

      def open_reader
        fail %(Pipe "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'r')
      end

      def open_writer
        fail %(Pipe "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'w')
      end
    end

    class SocketChannel
      def initialize(host, port)
        @host, @port = host, port
        @retry_counter = 3
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
    end
  end
end
