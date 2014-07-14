module DeadlySerious
  module Engine
    # Commands make work with Pipelines easier.
    module Commands

      private def auto_pipe
                @auto_pipe ||= AutoPipe.new
              end

      def on_subnet(&block)
        auto_pipe.on_subnet &block
      end

      def next_pipe
        auto_pipe.next
      end

      def last_pipe
        auto_pipe.last
      end

      # Read a file from "data" dir and pipe it to
      # the next component.
      def from_file(file_name, writer: next_pipe)
        file = file_name.sub(/^>?(.*)$/, '>\1')
        spawn_command('cat', reader: file, writer: writer)
      end

      # Write a file to "data" dir from the pipe
      # of the last component
      def to_file(file_name, reader: last_pipe)
        file = file_name.sub(/^>?(.*)$/, '>\1')
        spawn_command('cat', reader: reader, writer: file)
      end

      # Read from a specific named pipe.
      #
      # This is useful after a {#spawn_tee}, sometimes.
      def from_pipe(pipe_name, writer: next_pipe)
        pipe = pipe_name.sub(/^>?/, '')
        spawn_command('cat', reader: pipe, writer: writer)
      end

      # Write the output of the last component to
      # a specific named pipe.
      #
      # Unless you are connecting different pipelines,
      # avoid using this or check if you don't need
      # {#spawn_tee} instead.
      def to_pipe(pipe_name, reader: last_pipe)
        pipe = pipe_name.sub(/^>?/, '')
        spawn_command('cat', reader: reader, writer: pipe)
      end

      # Spawn a class connected to the last and next components
      def spawn_class(a_class, *args, reader: last_pipe, writer: next_pipe)
        spawn_process(a_class, *args, readers: [reader], writers: [writer])
      end

      # Spawn {number_of_processes} classes, one process for each of them.
      # Also, it divides the previous pipe in {number_of_processes} pipes,
      # an routes data through them.
      def spawn_class_parallel(number_of_processes, class_name, *args, reader: last_pipe, writer: next_pipe)
        connect_a = (1..number_of_processes).map { |i| sprintf('%s.%da.splitter', class_name.to_s.downcase.gsub(/\W+/, '_'), i) }
        connect_b = (1..number_of_processes).map { |i| sprintf('%s.%db.splitter', class_name.to_s.downcase.gsub(/\W+/, '_'), i) }
        spawn_process(DeadlySerious::Processes::Splitter, readers: [reader], writers: connect_a)
        connect_a.zip(connect_b).each do |a, b|
          spawn_class(class_name, *args, reader: a, writer: b)
        end
        spawn_process(DeadlySerious::Processes::Joiner, readers: connect_b, writers: [writer])
      end

      def spawn_lambda(reader: last_pipe, writer: next_pipe, &block)
        spawn_process(DeadlySerious::Processes::Lambda, block, readers: [reader], writers: [writer])
      end

      # Pipe from the last component to a intermediate
      # file (or pipe) while continue the process.
      #
      # If a block is provided, it pipes from the last
      # component INTO the block, while it pipes to the
      # next component OUT of the block.
      def spawn_tee(escape = nil, reader: nil, writer: nil, &block)
        # Lots of contours to make #last_pipe and and #next_pipe
        # to work correctly.
        reader ||= last_pipe
        writer ||= next_pipe

        if block_given?
          on_subnet do
            spawn_command("tee '#{create_pipe(next_pipe)}'", reader: reader, writer: writer)
            block.call
          end
        else
          spawn_command("tee '#{create_pipe(escape)}'", reader: reader, writer: writer)
        end
      end

      # Sometimes we need all previous process to end before
      # starting new processes. The capacitor command does
      # exactly that.
      def spawn_capacitor(charger_file = nil, reader: last_pipe, writer: next_pipe)
        if charger_file.nil?
          charger_file = ">#{last_pipe}"
        end
        fail "#{charger_file} must be a file" unless charger_file.start_with?('>')
        spawn_command('cat', reader: reader, writer: charger_file)
        spawn_command('cat', reader: charger_file, writer: writer)
      end
    end
  end
end
