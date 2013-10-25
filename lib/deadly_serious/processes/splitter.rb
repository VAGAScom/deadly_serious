module DeadlySerious
  module Processes
    class Splitter
      def initialize
        Signal.trap('USR1') { @outputs = @writers.dup }
      end
      def run(readers: [], writers: [])
        @writers ||= writers
	reader = readers.first
        @outputs = @writers.dup
        begin
          reader.each do |line|
            @current = @outputs.first
            @current << line
            @outputs.rotate!
          end
        rescue => e
          puts e.inspect
          @outputs.delete(@current)
          raise e if @outputs.empty?
          retry
        end
      end
    end
  end
end
