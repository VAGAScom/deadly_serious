require 'deadly_serious/engine/channel/socket/minion'
require 'deadly_serious/engine/channel/socket/master_mind'

module DeadlySerious
  module Engine
    class SocketChannel
      # Odd, but I had too :(
      require 'deadly_serious/engine/channel/socket/socket_vent_recvr'
      require 'deadly_serious/engine/channel/socket/socket_vent_sendr'
      require 'deadly_serious/engine/channel/socket/socket_sink_recvr'
      require 'deadly_serious/engine/channel/socket/socket_sink_sendr'
      include Enumerable

      END_MSG = 'END TRANSMISSION'.freeze
      RDY_MSG = 'READY FOR TRANSMISSION'.freeze

      DEFAULT_PORT = 10001
      REGEXP = /\A([<>][{}])([^:]+):(\d{1,5})\z/

      attr_reader :host, :port, :master

      def self.of_type(name)
        matcher = name.match(REGEXP)
        return if matcher.nil?
        type = matcher[1]
        case type
          when '>{'
            SocketVentSendr
          when '<{'
            SocketVentRecvr
          when '>}'
            SocketSinkSendr
          when '<}'
            SocketSinkRecvr
          else
            nil
        end
      end

      def initialize(name, _config)
        matcher = name.match(REGEXP)
        host = matcher[2]
        port = matcher[3]
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

      def self.create(_name, _config)
        # Do nothing
      end

      # Only for tests
      def context
        master.factory
      end
    end
  end
end