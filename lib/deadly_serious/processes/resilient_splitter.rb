module DeadlySerious
  module Processes
    class ResilientSplitter
      def initialize
        @reallocate = false
        Signal.trap('USR1') do
          @reallocate = true
        end
      end

      def run(readers: [], writers: [])
        reader = readers.first
        outputs = writers.dup
        current = nil
        reader.each do |line|
          begin
            if @reallocate
              @reallocate = false
              outputs = writers.dup
            end
            current = outputs.first
            current << line
            outputs.rotate!
          rescue Errno::EPIPE => e
            puts e.inspect
            outputs.delete(current)
            raise e if outputs.empty?
            redo
          end
        end
      end
    end
  end
end
