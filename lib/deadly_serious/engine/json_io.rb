require 'json'

module DeadlySerious
  module Engine
    class JsonIo
      def initialize(io)
        @io = io
      end

      def each
        @io.each { |line| yield JSON.parse(line) }
      end

      def <<(value)
        @io << value.to_json << "\n"
      end
    end
  end
end
