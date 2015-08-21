module DeadlySerious
  module Engine
    class SoCommandContainer
      INPUT_PATTERN = '((<))'
      OUTPUT_PATTERN = '((>))'
      attr_reader :name

      def initialize(a_shell_command, env, config, reader_names, writer_names)
        @env = env
        @config = config
        @reader_names = reader_names
        @writer_names = writer_names
        @name = Array(a_shell_command).join(' ')

        @shell_tokens = prepare_command(a_shell_command)
      end

      def run
        readers = @reader_names.map { |it| Channel.new(it, @config).create }
        writers = @writer_names.map { |it| Channel.new(it, @config).create }

        tokens = @shell_tokens.map do |token|
          case token
            when INPUT_PATTERN
              readers.shift || fail('Missing reader')
            when OUTPUT_PATTERN
              writers.shift || fail('Missing writer')
            else
              token.to_s
          end
        end

        in_out = {close_others: true,
                  in: readers.size == 1 ? [readers.first, 'r'] : :close,
                  out: writers.size == 1 ? [writers.first, 'w'] : :close}

        FileMonitor.new(*[readers, writers].flatten).wait_creation
        exec(@env, [tokens.first, name], *tokens[1..-1], in_out)
      end

      private

      def prepare_command(a_shell_command)
        case a_shell_command
          when Array
            a_shell_command
          else
            a_shell_command.to_s.split(/\s+/)
        end
      end
    end
  end
end