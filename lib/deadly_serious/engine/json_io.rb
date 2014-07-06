require 'json'

module DeadlySerious
  module Engine
    class JsonIo
      include Enumerable

      def initialize(io)
        @io = io
      end

      def each
        @io.each { |line| yield JSON.parse(line) }
      end

      def <<(value)
        case value
          when Hash
            @io << value.to_json << "\n"
          else
            @io << Array(value).to_json << "\n"
        end
      end

      def flush
        @io.flush
      end
    end
  end
end
