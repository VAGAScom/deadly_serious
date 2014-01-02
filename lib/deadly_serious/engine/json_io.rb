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

      def <<(value)
        @io << value.to_json << "\n"
      end
    end
  end
end
