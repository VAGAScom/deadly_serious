module DeadlySerious
  module Engine
    module BaseProcess
      def run(readers: [], writers:[])
        reader = readers.first
        @writer = writers.first

        reader.each { |packet| super(packet.chomp) }
      end

      def send(packet = nil)
        send_buffered(packet)
        flush_buffer
      end

      def send_buffered(packet = nil)
        @writer << packet if packet
        @writer << "\n"
      end

      def flush_buffer
        @writer.flush
      end
    end
  end
end

