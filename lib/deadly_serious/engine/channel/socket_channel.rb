autoload :SocketSender, 'deadly_serious/engine/channel/socket/socket_sender'
autoload :SocketReceiver, 'deadly_serious/engine/channel/socket/socket_receiver'
require 'deadly_serious/engine/channel/socket/minion'
require 'deadly_serious/engine/channel/socket/master_mind'

module DeadlySerious
  module Engine
    class SocketChannel
      include Enumerable

      END_MSG = 'END TRANSMISSION'.freeze
      DEFAULT_PORT = 10001
      attr_reader :host, :port, :master

      def self.new_if_match(name, _config)
        matcher = name.match(/\A(>>|<<)([^:]+):(\d{1,5})\z/)
        return if matcher.nil?
        if matcher[1] == '>>'
          SocketSender.new(matcher[2], matcher[3])
        else
          SocketReceiver.new(matcher[2], matcher[3])
        end
      end

      def initialize(host, port)
        @host = host.to_s.empty? ? 'localhost' : host.to_s
        @port = port.to_s.empty? ? DEFAULT_PORT : port.to_i
        @master = MasterMind.new_instance
      end

      def each
        fail 'Subclass implementation'
      end

      def <<(_data)
        fail 'Subclass implementation'
      end

      def close
        fail 'Subclass implementation'
      end

      def flush
        # Do nothing
      end

      def create
        # Do nothing
      end

      # Only for tests
      def context
        master.factory
      end
    end
  end
end