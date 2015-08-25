module DeadlySerious
  module Engine
    class SocketVentSendr < SocketChannel

      attr_reader :io_name

      def initialize(name, _config)
        super
        @io_name = format('tcp://*:%d', port)
        @minion = master.spawn_minion { |ctx| ctx.bind(:ROUTER, @io_name) }
        @receivers = Set.new
      end

      def <<(data)
        identity = @minion.recv # Stop until ready
        @receivers << identity
        @minion.recv # Discard message ("command")
        @minion.send_to(identity, data.to_s)
        self
      end

      def close
        @receivers.each do |identity|
          @minion.send_to(identity, END_MSG)
        end
        @minion.explode
      end
    end
  end
end
