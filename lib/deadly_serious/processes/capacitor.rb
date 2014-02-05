module DeadlySerious
  module Processes
    class Capacitor
      def run(readers: [], writers: [])
        reader = readers.first
        temp_file, writer = *writers

        reader.each { |row| temp_file << row }

        temp_file.close
        reader.close

        temp_file.each { |row| writer << row }
      end
    end
  end
end
