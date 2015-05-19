module DeadlySerious
  module Engine
    class JsonIo
      include Enumerable

      def initialize(io)
        @io = io
      end

      def each
        if block_given?
          @io.each { |line| yield parse_line(line) }
        else
          @io.lazy.map { |line| parse_line(line) }
        end
      end

      def parse_line(line)
        MultiJson.load(line)
      end

      def <<(value)
        case value
          when Hash
            @io << MultiJson.dump(value) << "\n"
          else
            @io << MultiJson.dump(Array(value)) << "\n"
        end
      end

      def flush
        @io.flush
      end
    end
  end
end
