module DeadlySerious
  module Engine
    module BaseProcess
      def run(readers: [], writers:[])
        reader = readers.first
        @writer = writers.first

        reader.each { |packet| super(packet.chomp) }
      end

      # Alias to #send
      def emit(packet = nil)
        send(packet)
      end

      # Send a packet to the next process
      def send(packet = nil)
        send_buffered(packet)
        flush_buffer
      end

      # Send a packet to the next process,
      # however, accumulate some of them
      # before send to gain a little
      # efficency.
      def send_buffered(packet = nil)
        @writer << packet if packet
        @writer << "\n"
      end

      # Send all not yet sent packets.
      def flush_buffer
        @writer.flush
      end
    end
  end
end

