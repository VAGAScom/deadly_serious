require 'deadly_serious/engine/json_io'

module DeadlySerious
  module Engine
    module SimpleJsonProcess
      def run(readers: [], writers: [])
        reader = JsonIo.new(readers.first) unless readers.empty?
        @writer = JsonIo.new(writers.first) unless writers.empty?

        if reader
          reader.each do |packet|
            super(packet)
          end
        else
          super
        end
      end

      # Alias to #send
      def emit(packet = nil)
        send(packet)
      end

      # Send a packet to the next process
      def send(packet = nil)
        raise 'No "writer" defined' unless @writer
        @writer << packet if packet
      end
    end
  end
end

