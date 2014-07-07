require 'deadly_serious/engine/channel'
require 'deadly_serious/engine/open_io'
require 'deadly_serious/engine/auto_pipe'
require 'deadly_serious/processes/splitter'

module DeadlySerious
  module Engine
    class Pipeline
      include DeadlySerious::Engine::Commands

      attr_reader :data_dir, :pipe_dir, :pids

      def initialize(data_dir: './data',
                     pipe_dir: "/tmp/deadly_serious/#{Process.pid}",
                     preserve_pipe_dir: false,
                     &block)
        @data_dir = data_dir
        @pipe_dir = pipe_dir
        @block = block
        @pids = []
        Channel.config(data_dir, pipe_dir, preserve_pipe_dir)
      end

      def run
        Channel.setup
        @block.call(self)
        wait_children
      rescue => e
        kill_children
        raise e
      ensure
        Channel.teardown
      end

      # Wait all sub processes to finish before
      # continue the pipeline.
      #
      # Always prefer to use {DeadlySerious::Engine::Commands#spawn_capacitor}
      # if possible.
      def wait_processes!
        wait_children
      end

      # Spawn a  class in a separated process.
      #
      # This is a basic command, use it only if you have
      # more than one input or output pipe. Otherwise
      # prefer the simplier {DeadlySerious::Engine::Commands#spawn_class}
      # method.
      def spawn_process(a_class, *args, process_name: a_class.name, readers: [last_pipe], writers: [next_pipe])
        # TODO if we have no readers, alarm! (how about data sources???)
        # TODO if we have no readers, and this is the first process, read from STDIN
        # TODO if we have no writers, alarm! (how about data sinks???)
        # TODO if we have no writers, and this is the last process, read from STDIN
        writers.each { |writer| create_pipe(writer) }
        @pids << fork do
          begin
            set_process_name(process_name, readers, writers)
            # TODO Change this to not modify "a_class", so we can pass instances too
            append_open_io_if_needed(a_class)
            the_object = a_class.new
            the_object.run(*args, readers: readers, writers: writers)
          rescue Errno::EPIPE # Broken Pipe, no problem
            # Ignore
          ensure
            the_object.finalize if the_object.respond_to?(:finalize)
          end
        end
      end

      def spawn_command(a_shell_command, reader: last_pipe, writer: next_pipe)
        input = create_pipe(reader).gsub("'", "\\'")
        output = create_pipe(writer).gsub("'", "\\'")
        @pids << spawn(a_shell_command + %( <'#{input}') + %( >'#{output}'))
      end

      private

      def append_open_io_if_needed(a_class)
        a_class.send(:prepend, OpenIo) unless a_class.include?(OpenIo)
      end

      def create_pipe(pipe_name)
        Channel.create_pipe(pipe_name)
      end

      def wait_children
        @pids.each { |pid| Process.wait(pid) }
        @pids.clear
      end

      def kill_children
        @pids.each { |pid| Process.kill('SIGTERM', pid) rescue nil }
        wait_children
      end

      def set_process_name(name, readers, writers)
        $0 = "ruby #{self.class.dasherize(name)} <(#{readers.join(' ')}) >(#{writers.join(' ')})"
      end

      def self.dasherize(a_string)
        a_string.gsub(/(.)([A-Z])/, '\1-\2').downcase.gsub(/\W+/, '-')
      end
    end
  end
end