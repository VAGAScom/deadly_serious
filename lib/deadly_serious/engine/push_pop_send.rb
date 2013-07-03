
module DeadlySerious
  module Engine
    module PushPopSend
      attr_reader :stack

      def run(readers: [], writers: [])
        reader = readers.first
        @writer = writers.first

        reset_stack
        reader.each { |packet| super(packet.chomp) }
      end

      def push(value)
        @stack.push(value)
      end

      def pop
        @stack.pop
      end

      def send(packet = nil)
        @writer << packet if packet
        @writer << "\n"
      end

      def top_stack(quantity)
        @stack[(-quantity)..-1]
      end

      def reset_stack
        @stack = []
      end
    end
  end
end
