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
        existing_file = FileMonitor.new(@io_name).wait_file_creation
        open(existing_file, 'r') { |file| file.each_line { |line| yield line } }
      end

      def <<(data)
        @writer ||= begin
          create
          open(@io_name, 'w')
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
        # file existence it but STILL tries to create
        # the pipe due concurrency :(
        # Not good >_<
        `mkfifo '#{@io_name}' 2>/dev/null` unless File.exist?(@io_name)
        @io_name
      end
    end
  end
end