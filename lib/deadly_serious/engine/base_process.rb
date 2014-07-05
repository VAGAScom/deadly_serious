module DeadlySerious
  module Engine
    # @deprecated Simplifying, simplifying, simplifying
    module BaseProcess
      def run(readers: [], writers:[])
        reader = readers.first
        @writer = writers.first

        if reader
          reader.each { |packet| super(packet.chomp) }
        else
          super()
        end
      rescue Errno::EPIPE
        # Ignore it. We expect that sometimes =)
      end

      # Send a packet to the next process
      def send(packet = nil)
        send_buffered(packet)
        flush_buffer
      end

      alias :emit :send

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

