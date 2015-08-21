module DeadlySerious
  module Engine
    class FileChannel
      include Enumerable

      attr_reader :io_name

      def self.new_if_match(name, config)
        matcher = name.match(/\A>(.*?)\z/)
        self.new(matcher[1], config.data_dir) if matcher
      end

      def initialize(name, directory)
        if name =~ /^\//
          # Absolute file path
          @io_name = name
        else
          # relative file path (relative to data_dir)
          @io_name = File.join(directory, name)
        end
      end

      def each
        return enum_for(:each) unless block_given?
        existing_file = FileMonitor.new(@io_name).wait_creation
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
        `touch '#{@io_name}'` unless File.exist?(@io_name)
        @io_name
      end
    end
  end
end