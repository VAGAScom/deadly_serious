module DeadlySerious
  module Processes
    class Lambda
      def run(*args, block, readers:, writers:)
        block.call(readers.first, writers.first, args)
      end
    end
  end
end