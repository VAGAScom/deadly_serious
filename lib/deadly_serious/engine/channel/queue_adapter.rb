module DeadlySerious
  module Engine
    class QueueAdapter

      include Enumerable
      def initialize(queue)
        @queue = queue
      end

      def gets
        @queue.receive
      end

      def each(&block)
        open_reader
        @io.each &block
      end

      def <<(element)
        @queue.send(element)
      end

      def eof?
        @queue.nil?
      end

      def closed?
        @queue.nil?
      end

      def close
        @queue.unlink unless closed?
        @queue = nil
      end

      def flush
        # Do nothing
      end
    end
  end
end
