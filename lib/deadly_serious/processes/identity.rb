module DeadlySerious
  module Processes
    class Identity
      def run(readers: [], writers: [])
        reader = readers.first
        reader.each do |line|
          writers.each { |w| w << line }
        end
      end
    end
  end
end
