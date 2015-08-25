module DeadlySerious
  module Engine
    class FileChannel
      include Enumerable

      REGEXP = /\A>(.*?)\z/

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
        @writer ||= open(@io_name, 'w')
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
        file_name = matcher[1]
        config.file_path_for(file_name)
      end

      def self.create(name, config)
        io_name = io_name_for(name, config)
        `touch '#{io_name}'` unless File.exist?(io_name)
        io_name
      end
    end
  end
end