module DeadlySerious
  module Engine
    class Minion
      extend Forwardable

      def_delegators :@brain, :send, :recv

      def initialize(mastermind, brain)
        @mastermind = mastermind
        @brain = brain
      end

      def send_to(destiny, msg)
        @brain.sendm(destiny)
        @brain.send(msg)
      end

      def explode
        @brain.close
        @mastermind.destroy_body_of(self)
      end
    end
  end
end
