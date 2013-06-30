module DeadlySerious
  module Processes
    class Joiner
      def run(readers: [], writers: [])
        writer = writers.first
        until readers.all?(&:eof?)
          readers.each do |reader|
            line = reader.gets
            writer << line if line
          end
        end
      end
    end
  end
end
