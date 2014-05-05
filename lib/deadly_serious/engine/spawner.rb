require 'deadly_serious/engine/channel'
require 'deadly_serious/engine/open_io'
require 'deadly_serious/engine/auto_pipe'
require 'deadly_serious/processes/splitter'

module DeadlySerious
  module Engine
    class Spawner
      def initialize(data_dir: './data',
                     pipe_dir: "/tmp/deadly_serious/#{Process.pid}",
                     preserve_pipe_dir: false)
        @ids = []
        @auto_pipe = AutoPipe.new
        Channel.config(data_dir, pipe_dir, preserve_pipe_dir)
      end

      def on_subnet(&block)
        @auto_pipe.on_subnet &block
      end

      def next_pipe
        @auto_pipe.next
      end

      def last_pipe
        @auto_pipe.last
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

      def wait_processes!
        wait_children
      end

      def spawn_process(a_class, *args, process_name: a_class.name, readers: [], writers: [])
        writers.each { |writer| create_pipe(writer) }
        fork_it do
          begin
            set_process_name(process_name, readers, writers)
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

      def spawn_processes(a_class, *args, process_name: a_class.name, reader_pattern: nil, writers: [])
        number = last_number(reader_pattern)

        loop do
          this_reader = pattern_replace(reader_pattern, number)
          break unless Channel.exists?(this_reader)
          spawn_process(a_class,
                        *args,
                        process_name: process_name,
                        readers: [this_reader],
                        writers: Array(writers))
          number += 1
        end
      end

      def spawn_source(a_class, *args, writer: a_class.dasherize(a_class.name))
        spawn_process(a_class, *args, process_name: process_name, readers: [], writers: [writer])
      end

      def spawn_splitter(process_name: 'Splitter', reader: nil, writer: '>output01.txt', number: 2)
        start = last_number(writer)
        finish = start + number - 1

        writers = (start..finish).map { |index| pattern_replace(writer, index) }

        spawn_process(Processes::Splitter,
                      process_name: process_name,
                      readers: Array(reader),
                      writers: writers)
      end

      def spawn_socket_splitter(process_name: 'SocketSplitter', reader: nil, port: 11000, number: 2)
        spawn_splitter(process_name: process_name,
                       reader: reader,
                       writer: "localhost:#{port}",
                       number: number)
      end

      def spawn_command(a_shell_command)
        command = a_shell_command.dup
        a_shell_command.scan(/\(\((.*?)\)\)/) do |(pipe_name)|
          pipe_path = create_pipe(pipe_name)
          command.gsub!("((#{pipe_name}))", "'#{pipe_path.gsub("'", "\\'")}'")
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
        @ids.clear
      end

      def kill_children
        @ids.each { |id| Process.kill('SIGTERM', id) rescue nil }
        wait_children
      end

      def set_process_name(name, readers, writers)
        $0 = "ruby #{self.class.dasherize(name)} <(#{readers.join(' ')}) >(#{writers.join(' ')})"
      end

      # @!endgroup
      # @!group Minor Helpers

      def self.dasherize(a_string)
        a_string.gsub(/(.)([A-Z])/, '\1-\2').downcase.gsub(/\W+/, '-')
      end

      def last_number_pattern(a_string)
        last_number_pattern = /(\d+)[^\d]*$/.match(a_string)
        raise %(Writer name "#{writer}" should have a number) if last_number_pattern.nil?

        last_number_pattern[1]
      end

      def last_number(a_string)
        last_number_pattern(a_string).to_i
      end

      def pattern_replace(a_string, number)
        pattern = last_number_pattern(a_string)
        pattern_length = pattern.size
        find_pattern = /#{pattern}([^\d]*)$/
        replace_pattern = "%0.#{pattern_length}d\\1"

        a_string.sub(find_pattern, sprintf(replace_pattern, number))
      end
    end
  end
end

if __FILE__ == $0
  DeadlySerious::Engine::Spawner.new.run
end
