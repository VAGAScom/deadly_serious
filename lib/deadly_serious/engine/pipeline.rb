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
      # prefer the simpler {DeadlySerious::Engine::Commands#spawn_class} or
      # the {DeadlySerious::Engine::Commands#spawn} methods.
      def spawn_process(class_or_object, *args, process_name: nil, readers: [last_pipe], writers: [next_pipe])
        # TODO if we have no readers, alarm! (how about data sources???)
        # TODO if we have no readers, and this is the first process, read from STDIN
        # TODO if we have no writers, alarm! (how about data sinks???)
        # TODO if we have no writers, and this is the last process, write to STDOUT
        process_name ||= class_or_object.respond_to?(:name) ? class_or_object.name : class_or_object.to_s
        writers.each { |writer| create_pipe(writer) }
        @pids << fork do
          begin
            set_process_name(process_name, readers, writers)
            # TODO Change this to not modify "a_class", so we can pass instances too
            the_object = Class === class_or_object ? class_or_object.new : class_or_object
            append_open_io_if_needed(the_object)
            the_object.run(*args, readers: readers, writers: writers)
          rescue Errno::EPIPE # Broken Pipe, no problem
            # Ignore
          ensure
            the_object.finalize if the_object.respond_to?(:finalize)
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


        shell_tokens = case a_shell_command
                         when Array
                           a_shell_command
                         else
                           a_shell_command.to_s.split(/\s+/)
                       end

        inputs = readers.map { |it| create_pipe(it) }
        outputs = writers.map { |it| create_pipe(it) }

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

      def append_open_io_if_needed(an_object)
        class << an_object
          prepend OpenIo
        end
      end

      def create_pipe(pipe_name)
        Channel.create_pipe(pipe_name)
      end

      def wait_children
        # Don't wait if we have no children
        # Thread.start do
        #   while @pids.size > 1
        #     @pids.each do |pid|
        #       begin
        #         Process.wait(pid, Process::WNOHANG)
        #       rescue Errno::ECHILD
        #         puts "Try delete #{pid}"
        #         @pids.delete(pid)
        #       end
        #     end
        #     sleep(0.5)
        #   end
        # end
        Process.waitall
        @pids.clear
      end

      def kill_children
        gpid = Process.gid
        Process.kill('SIGTERM', -gpid) rescue nil
        Timeout::timeout(5) { wait_children }
      rescue Timeout::Error
        Process.kill('SIGKILL', -gpid) rescue nil
      end

      def set_process_name(name, readers, writers)
        $0 = format('(%s)-->[%s]-->(%s)', readers.join(', '), name, writers.join(' '))
      end
    end
  end
end
