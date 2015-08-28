module DeadlySerious
  module Engine
    class SocketVentRecvr < SocketChannel

      attr_reader :io_name

      def initialize(name, _config)
        super
        @io_name = format('tcp://%s:%d', host, port)
        @minion = master.spawn_minion do |ctx, counter|
          socket = ctx.socket(:DEALER)
          socket.identity = format('%d:%d', Process.pid, counter)
          socket.connect(@io_name)
          socket
        end
      end

      def each
        return enum_for(:each) unless block_given?
        @minion.send('') # I'm ready!
        while (msg = @minion.recv) != END_MSG
          @minion.send('') # More msg, pls!
          yield msg
        end
      end

      def close
        @minion.explode
      end
    end
  end
end