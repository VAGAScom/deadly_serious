module DeadlySerious
  module Engine
    class Pipeline
      include DeadlySerious::Engine::Commands

      attr_reader :pids, :config

      def initialize(data_dir: './data',
                     pipe_dir: "/tmp/deadly_serious/#{Process.pid}",
                     preserve_pipe_dir: false,
                     &block)

        @config = Config.new(data_dir: data_dir, pipe_dir: pipe_dir, preserve_pipe_dir: preserve_pipe_dir)
        @block = block
        @pids = []
      end

      def run
        @config.setup
        @block.call(self)
        wait_children
      rescue => e
        kill_children
        raise e
      ensure
        @config.teardown if @config
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
      # prefer the simpler {DeadlySerious::Engine::Commands#spawn_class} or
      # the {DeadlySerious::Engine::Commands#spawn} methods.
      def spawn_process(class_or_object, *args, process_name: nil, readers: [last_pipe], writers: [next_pipe])
        writers.compact.each { |w| Channel.of_type(w).create(w, @config) }
        @pids << fork do
          begin
            container = RubyObjectContainer.new(class_or_object,
                                                args,
                                                process_name,
                                                @config,
                                                readers.compact,
                                                writers.compact)
            set_process_name(container.name)
            container.run
          rescue Errno::EPIPE # Broken Pipe, no problem
            # Ignore
          ensure
            container.finalize if container
          end
        end
      end

      def spawn_command(a_shell_command, env: {}, readers: [last_pipe], writers: [next_pipe])
        writers.compact.each { |w| Channel.of_type(w).create(w, @config) }
        @pids << fork do
          begin
            container = SoCommandContainer.new(a_shell_command,
                                               env,
                                               @config,
                                               readers.compact,
                                               writers.compact)
            set_process_name(container.name)
            container.run
          rescue Errno::EPIPE # Broken Pipe, no problem
            # Ignore
          end
        end
      end

      private

      def wait_children
        Process.waitall
      end

      def kill_children
        gpid = Process.gid
        Process.kill('SIGTERM', -gpid) rescue nil
        Timeout::timeout(5) { wait_children }
        @pids.clear
      rescue Timeout::Error
        Process.kill('SIGKILL', -gpid) rescue nil
      end

      def set_process_name(name)
        $0 = name
      end
    end
  end
end
