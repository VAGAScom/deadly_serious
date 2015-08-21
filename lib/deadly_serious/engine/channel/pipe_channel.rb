module DeadlySerious
  module Engine
    class PipeChannel
      include Enumerable

      attr_reader :io_name

      def self.new_if_match(name, config)
        matcher = name.match(/\A(.*?)\z/)
        self.new(matcher[1], config.pipe_dir) if matcher
      end

      def initialize(name, directory)
        if name =~ /^\//
          # Absolute pipe path
          @io_name = name
        else
          # relative pipe path (relative to pipe_dir)
          @io_name = File.join(directory, name)
        end
      end

      def each
        return enum_for(:each) unless block_given?
        existing_file = FileMonitor.new(@io_name).wait_creation
        open(existing_file, 'r') { |file| file.each_line { |line| yield line } }
      end

      def <<(data)
        retries = 3
        @writer ||= begin
          create
          open(@io_name, File::WRONLY | File::NONBLOCK)
        rescue Errno::ENXIO
          raise if retries <= 0
          sleep 0.5
          retries -= 1
          retry
        end
        @writer.print(data)
        self
      end

      def flush
        @writer.flush if @writer
      end

      def close
        @writer.close if @writer
      end

      def create
        # Redirecting to /dev/null when we test the
        # file existence. It STILL tries to create
        # the pipe due concurrency :(
        # Not good >_<
        `mkfifo '#{@io_name}' 2>/dev/null` unless File.exist?(@io_name)
        @io_name
      end

      private

      def retries(times = 3, sleep = 0.5)
      end
    end
  end
end