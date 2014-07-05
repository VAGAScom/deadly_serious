module DeadlySerious
  module Engine
    # @deprecated Simplifying, simplifying, simplifying
    module PushPop
      attr_reader :stack

      def push(value)
        stack.push(value)
      end

      def pop
        stack.pop
      end

      def top_stack(quantity)
        stack[(-quantity)..-1]
      end

      def stack
        @stack ||= []
      end

      def reset_stack
        @stack = []
      end
    end
  end
end
