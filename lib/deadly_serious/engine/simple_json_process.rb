require 'deadly_serious/engine/json_io'

module DeadlySerious
  module Engine
    module SimpleJsonProcess

      def run(readers: [], writers: [])
        reader = JsonIo.new(readers.first) unless readers.empty?
        @writer = JsonIo.new(writers.first) unless writers.empty?

        if reader
          reader.each do |packet|
            if packet.is_a? Array
              super(*packet)
            else
              super(packet)
            end
          end
        else
          super()
        end
      rescue Errno::EPIPE
        # Ignore it. We expect that sometimes =)
      end

      # Send a packet to the next process
      def send(*packet)
        raise 'No "writer" defined' unless @writer
        @writer << packet unless packet.empty?
      end

      alias :emit :send
    end
  end
end

