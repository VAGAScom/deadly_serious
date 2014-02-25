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
        @io << value.to_json << "\n"
      end

      def flush
        @io.flush
      end
    end
  end
end
