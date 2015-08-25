module DeadlySerious
  module Engine
    class PipeChannel
      include Enumerable

      REGEXP = /\A(.*?)\z/

      attr_reader :io_name

      def self.of_type(name)
        self if name.match(REGEXP)
      end

      def initialize(name, config)
        @io_name = self.class.io_name_for(name, config)
      end

      def each
        return enum_for(:each) unless block_given?
        open(io_name, 'r') { |file| file.each_line { |line| yield line } }
      end

      def <<(data)
        @writer ||= open(@io_name, File::WRONLY)
        @writer.print(data)
        self
      end

      def flush
        @writer.flush if @writer
      end

      def close
        @writer.close if @writer
      end

      def self.io_name_for(name, config)
        matcher = name.match(REGEXP)
        pipe_name = matcher[1]
        config.pipe_path_for(pipe_name)
      end

      def self.create(name, config)
        # Redirecting to /dev/null when we test the
        # file existence. It STILL tries to create
        # the pipe due concurrency :(
        # Not good >_<
        io_name = io_name_for(name, config)
        `mkfifo '#{io_name}' 2>/dev/null` unless File.exist?(io_name)
        io_name
      end

      private

      def retries(times = 3, sleep = 0.5)
      end
    end
  end
end