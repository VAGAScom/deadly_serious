module DeadlySerious
  module Engine
    class JsonIo
      include Enumerable

      def initialize(io)
        @io = io
      end

      def each
        return enum_for(:each) unless block_given?
        @io.each { |line| yield MultiJson.load(line) }
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
