module DeadlySerious
  module Engine
    class FileMonitor
      class Parts
        attr_reader :directory, :name

        def initialize(file_name)
          matcher = file_name.to_s.match(%r{\A((?<dir>.*)/)?(?<name>[^/]+)\z})
          @directory = matcher[:dir]
          @name = matcher[:name]
        end

        def exist?
          File.exist?(to_s)
        end

        def to_s
          File.join(@directory, @name)
        end
      end

      def initialize(*file_names)
        @parts = file_names.map { |f| Parts.new(f) }
      end

      def wait_creation
        part = @parts.find { |p| p.exist? }
        return part.to_s if part
        watch_event(@parts, :create)
      end

      def wait_modification
        notifier = INotify::Notifier.new
        @parts.each { |p| notifier.watch(p.to_s, :modify) { Fiber.yield p.to_s } }
        fiber = Fiber.new { notifier.process }
        fiber.resume
      end

      private

      def watch_event(parts, event)
        dirs = parts.group_by(&:directory)
        notifier = INotify::Notifier.new
        dirs.each do |dir, ps|
          files = ps.map(&:name)
          notifier.watch(dir, event) do |e|
            Fiber.yield(File.join(dir, e.name)) if files.include?(e.name)
          end
        end
        fiber = Fiber.new { notifier.run }
        file_name = fiber.resume
        notifier.stop
        file_name
      end
    end
  end
end