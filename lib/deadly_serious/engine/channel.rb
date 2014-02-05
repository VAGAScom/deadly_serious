require 'socket'
require 'deadly_serious/engine/lazy_io'

module DeadlySerious
  module Engine
    # Fake class, it's actually a factory ¬¬
    module Channel
      def self.new(name)
        matcher = name.match(/^(>)?(.*?)(?:(:)(\d{1,5}))?$/)
        if matcher[1] == '>'
          FileChannel.new(matcher[2], @data_dir)
        elsif matcher[3] == ':'
          SocketChannel.new(matcher[2], matcher[4].to_i)
        else
          PipeChannel.new(matcher[2], @pipe_dir)
        end
      end

      def self.config(data_dir, pipe_dir, preserve_pipe_dir)
        @data_dir = data_dir
        @pipe_dir = pipe_dir
        @preserve_pipe_dir = preserve_pipe_dir
      end

      def self.setup
        FileUtils.mkdir_p(@pipe_dir) unless File.exist?(@pipe_dir)
      end

      def self.teardown
        if !@preserve_pipe_dir && File.exist?(@pipe_dir)
          FileUtils.rm_r(@pipe_dir, force: true, secure: true)
        end
      end

      def self.create_pipe(pipe_name)
        new(pipe_name).create
      end
    end

    class FileChannel
      attr_reader :io_name

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

      def io
        LazyIo.new(self)
      end
    end

    class PipeChannel
      attr_reader :io_name

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

      def io
        LazyIo.new(self)
      end
    end

    class SocketChannel
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
