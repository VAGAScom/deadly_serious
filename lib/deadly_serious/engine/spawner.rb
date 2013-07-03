require 'fileutils'
require 'deadly_serious/engine/channel'

module DeadlySerious
  module Engine
    class Spawner
      def initialize(data_dir: './data', pipe_dir: "/tmp/deadly_serious/#{Process.pid}", preserve_pipe_dir: false)
        @data_dir = data_dir
        @pipe_dir = pipe_dir
        @ids = []

        FileUtils.mkdir_p(pipe_dir) unless File.exist?(pipe_dir)

        unless preserve_pipe_dir
          at_exit { FileUtils.rm_r(pipe_dir, force: true, secure: true) }
        end
      end

      def self.dasherize(a_string)
        a_string.gsub(/(.)([A-Z])/, '\1-\2').downcase.gsub(/\W+/, '-')
      end

      def set_process_name(name)
        $0 = "ruby #{self.class.dasherize(name)}"
      end

      def channel_for(pipe_name)
        Channel.new(pipe_name, data_dir: @data_dir, pipe_dir: @pipe_dir)
      end

      def create_pipe(pipe_name)
        channel_for(pipe_name).create
      end

      def read_pipe(pipe_name)
        channel_for(pipe_name).open_reader
      end

      def write_pipe(pipe_name)
        channel = channel_for(pipe_name)
        return channel.open_writer unless block_given?

        channel.open_writer do |io|
          yield io
        end
      end

      def fork_it
        @ids << fork do
          yield
        end
      end

      def wait_children
        @ids.each { |id| Process.wait(id) }
      end

      def kill_children
        @ids.each { |id| Process.kill('SIGTERM', id) }
        wait_children
      end

      def spawn_source(a_class, *args, writer: self.class.dasherize(a_class.name))
        create_pipe(writer)
        fork_it do
          set_process_name(a_class.name)
          write_pipe(writer) do
            a_class.new.run(io, *args)
          end
        end
      end

      def spawn_process(a_class, *args, readers: [], writers: [])
        writers.each { |writer| create_pipe(writer) }
        fork_it do
          set_process_name(a_class.name)
          open_readers = readers.map { |reader| read_pipe(reader) }
          open_writers = writers.map { |writer| write_pipe(writer) }
          begin
            a_class.new.run(*args, readers: open_readers, writers: open_writers)
          ensure
            open_writers.each { |writer| writer.close unless writer.closed? }
            open_readers.each { |reader| reader.close unless reader.closed? }
          end
        end
      end

      def run
        run_pipeline
        wait_children
      rescue Exception => e
        kill_children
        raise e
      end
    end
  end
end

if __FILE__ == $0
  DeadlySerious::Engine::Spawner.new.run
end