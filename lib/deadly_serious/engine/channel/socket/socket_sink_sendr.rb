module DeadlySerious
  module Engine
    class SocketSinkSendr < SocketChannel

      attr_reader :io_name

      def initialize(name, _config)
        super
        @io_name = format('tcp://%s:%d', host, port)
        @minion = master.spawn_minion { |ctx| ctx.connect(:PUSH, @io_name) }
        sleep(0.5) # Avoid slow joiner syndrome the stupid way >(
        @minion.send(RDY_MSG)
      end

      def <<(data)
        @minion.send(data.to_s)
        self
      end

      def close
        @minion.send(END_MSG)
        @minion.explode
      end
    end
  end
end
