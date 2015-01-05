module DeadlySerious
  module Engine
    class ShellCommand
      def initialize(command, env: {}, name: nil)
        @command = prepare_command(command)
        @env = env
        @name = name
      end

      def spawn(input: nil, output: nil)
        fork { exec(@env, [@command.first, @name], *@command[1..-1], in_out(input, output)) }
      end

      private

      def in_out(input, output)
        {close_others: true,
         in: input ? [input, 'r'] : :close,
         out: output ? [output, 'w'] : :close}
      end

      def prepare_command(command)
        case command
          when Array
            command
          else
            command.to_s.split(/\s+/)
        end
      end
    end
  end
end