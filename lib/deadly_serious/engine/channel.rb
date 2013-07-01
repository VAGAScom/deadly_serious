module DeadlySerious
  module Engine
    class Channel
      def initialize(name, dir: nil)
        matcher = name.match(/^(>?)(.*)$/)
        @type = matcher[1] == '>' ? :file : :pipe
        name = matcher[2]
        @io_name = "#{dir}/#{name}"
      end

      def create
        return if File.exist?(@io_name)
        if @type == :file
          `touch #{@io_name}`
        else
          `mkfifo #{@io_name}`
        end
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
