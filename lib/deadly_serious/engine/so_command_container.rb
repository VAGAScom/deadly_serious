module DeadlySerious
  module Engine
    class SoCommandContainer
      INPUT_PATTERN = '((<))'
      OUTPUT_PATTERN = '((>))'
      attr_reader :name

      def initialize(a_shell_command, env, config, reader_names, writer_names)
        @env = env
        @readers = reader_names.map { |r| Channel.of_type(r).io_name_for(r, config) }
        @writers = writer_names.map { |w| Channel.of_type(w).io_name_for(w, config) }
        @name = Array(a_shell_command).join(' ')
        @tokens = prepare_command(a_shell_command)
      end

      def run
        in_out = {close_others: true,
                  in: @readers.size == 1 ? [@readers.first, 'r'] : :close,
                  out: @writers.size == 1 ? [@writers.first, 'w'] : :close}

        exec(@env, [@tokens.first, name], *@tokens[1..-1], in_out)
      end

      private

      def prepare_command(a_shell_command)
        shell_tokens = shell_tokens(a_shell_command)
        replace_placeholders(shell_tokens)
      end

      def shell_tokens(a_shell_command)
        case a_shell_command
          when Array
            a_shell_command
          else
            a_shell_command.to_s.split(/\s+/)
        end
      end

      def replace_placeholders(shell_tokens)
        shell_tokens.map do |token|
          case token
            when INPUT_PATTERN
              @readers.shift || fail('Missing reader')
            when OUTPUT_PATTERN
              @writers.shift || fail('Missing writer')
            else
              token.to_s
          end
        end
      end
    end
  end
end