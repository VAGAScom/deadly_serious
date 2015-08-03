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

      def spawn_command(a_shell_command, env: {}, reader: nil, writer: nil, readers: [], writers: [])
        input_pattern = '((<))'
        output_pattern = '((>))'

        if reader.nil? && readers.empty?
          readers << last_pipe
        elsif reader && readers.empty?
          readers << reader
        end

        if writer.nil? && writers.empty?
          writers << next_pipe
        elsif writer && writers.empty?
          writers << writer
        end

        inputs = readers.compact.map { |it| Channel.new(it, @config).create }
        outputs = writers.compact.map { |it| Channel.new(it, @config).create }

        shell_tokens = case a_shell_command
                         when Array
                           a_shell_command
                         else
                           a_shell_command.to_s.split(/\s+/)
                       end

        tokens = shell_tokens.map do |token|
          case token
            when input_pattern
              inputs.shift || fail('Missing reader')
            when output_pattern
              outputs.shift || fail('Missing writer')
            else
              token.to_s
          end
        end

        in_out = {close_others: true,
                  in: inputs.size == 1 ? [inputs.first, 'r'] : :close,
                  out: outputs.size == 1 ? [outputs.first, 'w'] : :close}

        description = "#{tokens.first} #{in_out}"
        @pids << fork { exec(env, [tokens.first, description], *tokens[1..-1], in_out) }
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
