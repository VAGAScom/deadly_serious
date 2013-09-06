require 'deadly_serious/engine/channel'
require 'deadly_serious/engine/open_io'

module DeadlySerious
  module Engine
    class Spawner
      def initialize(data_dir: './data',
                     pipe_dir: "/tmp/deadly_serious/#{Process.pid}",
                     preserve_pipe_dir: false)
        @ids = []
        Channel.config(data_dir, pipe_dir, preserve_pipe_dir)
      end

      def run
        Channel.setup
        run_pipeline
        wait_children
      rescue => e
        kill_children
        raise e
      ensure
        Channel.teardown
      end

      def spawn_source(a_class, *args, writer: a_class.dasherize(a_class.name))
        create_pipe(writer)
        fork_it do
          set_process_name(a_class.name)
          append_open_io_if_needed(a_class)
          a_class.new.run(io, *args)
        end
      end

      def spawn_process(a_class, *args, readers: [], writers: [])
        writers.each { |writer| create_pipe(writer) }
        fork_it do
          set_process_name(a_class.name)
          append_open_io_if_needed(a_class)
          a_class.new.run(*args, readers: readers, writers: writers)
        end
      end

      def spawn_command(a_shell_command)
        command = a_shell_command.dup
        a_shell_command.scan(/\(\((.*?)\)\)/) do |(pipe_name)|
          pipe_path = create_pipe(pipe_name)
          command.gsub!("((#{pipe_name}))", pipe_path)
        end
        @ids << spawn(command)
      end

      private

      def append_open_io_if_needed(a_class)
        a_class.send(:prepend, OpenIo) unless a_class.include?(OpenIo)
      end

      def create_pipe(pipe_name)
        Channel.create_pipe(pipe_name)
      end

      # @!group Process Control

      def fork_it
        @ids << fork { yield }
      end

      def wait_children
        @ids.each { |id| Process.wait(id) }
      end

      def kill_children
        @ids.each { |id| Process.kill('SIGTERM', id) }
        wait_children
      end

      def set_process_name(name)
        $0 = "ruby #{self.class.dasherize(name)}"
      end

      # @!endgroup
      # @!group Minor Helpers

      def self.dasherize(a_string)
        a_string.gsub(/(.)([A-Z])/, '\1-\2').downcase.gsub(/\W+/, '-')
      end
    end
  end
end

if __FILE__ == $0
  DeadlySerious::Engine::Spawner.new.run
end
