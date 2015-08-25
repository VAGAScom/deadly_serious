module DeadlySerious
  module Engine
    class SocketSinkRecvr < SocketChannel

      attr_reader :io_name

      def initialize(name, _config)
        super
        @io_name = format('tcp://*:%d', port)
        @minion = master.spawn_minion { |ctx| ctx.bind(:PULL, @io_name) }
      end

      def each
        return enum_for(:each) unless block_given?
        clients = 0
        loop do
          msg = @minion.recv
          if msg == END_MSG
            clients -= 1
            break if clients <= 0
          elsif msg == RDY_MSG
            clients += 1
          else
            yield msg
          end
        end
      end

      def close
        @minion.explode
      end
    end
  end
end
