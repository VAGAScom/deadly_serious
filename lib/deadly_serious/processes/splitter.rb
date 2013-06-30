module DeadlySerious
  module Processes
    class Splitter
      def run(readers: [], writers: [])
        reader = readers.first
        outputs = writers.dup
        reader.each do |line|
          outputs.first << line
          outputs.rotate!
        end
      end
    end
  end
end
