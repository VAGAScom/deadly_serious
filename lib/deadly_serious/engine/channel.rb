module DeadlySerious
  module Engine
    class Channel
      def initialize(name, data_dir: nil, pipe_dir: nil)
        matcher = name.match(/^(>?)(.*)$/)
        @type = matcher[1] == '>' ? :file : :pipe
        name = matcher[2]
        @io_name = if @type == :file
                     "#{data_dir}/#{name}"
                   else
                     "#{pipe_dir}/#{name}"
                   end
      end

      # Create a pipe or file (acording to name)
      # and returns the full name of the thing created.
      def create
        return @io_name if File.exist?(@io_name)
        if @type == :file
          `touch #{@io_name}`
        else
          `mkfifo #{@io_name}`
        end
        @io_name
      end

      def open_reader
        fail %(File "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'r')
      end

      def open_writer
        fail %(File "#{@io_name}" not found) unless File.exist?(@io_name)
        open(@io_name, 'w')
      end
    end
  end
end
