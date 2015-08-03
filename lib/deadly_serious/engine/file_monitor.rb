module DeadlySerious
  module Engine
    class FileMonitor
      def initialize(file_name)
        match = file_name.to_s.match(%r{\A((?<dir>.*)/)?(?<name>[^/]+)\z})
        @directory = match[:dir]
        @name = match[:name]
      end

      def wait_file_creation
        file_name = File.join(@directory, @name)
        if File.exist?(file_name)
          file_name
        else
          watch_creation(@directory, @name)
        end
      end

      def watch_creation(directory, name)
        enum = Enumerator.new do |y|
          notifier = INotify::Notifier.new
          notifier.watch(directory, :create) do |e|
            y << e.name and n.stop if e.name == name
          end
          notifier.run
        end
        file_name = enum.next
        File.join(directory, file_name)
      end
    end
  end
end