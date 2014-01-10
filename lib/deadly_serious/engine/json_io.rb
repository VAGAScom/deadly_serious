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

      def each_cons(qty)
        @io.each_cons(qty) do |args|
          yield *(args.map { |line| JSON.parse(line) })
        end
      end

      def each_with_object(object)
        @io.each_with_object(object) { |line, object| yield JSON.parse(line), object }
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
