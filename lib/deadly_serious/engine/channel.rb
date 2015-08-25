require 'deadly_serious/engine/channel/socket_channel'
require 'deadly_serious/engine/channel/file_channel'
require 'deadly_serious/engine/channel/pipe_channel'

module DeadlySerious
  module Engine

    CHANNELS = [SocketChannel, FileChannel, PipeChannel]

    # Fake class, it's actually a factory ¬¬
    #
    # name = '>xxx'     # File
    # name = 'xxx'      # Pipe
    # name = 'xxx:999'  # Socket
    # name = '!xxx:999' # 0MQueue
    module Channel
      def self.new(name, config)
        of_type(name).new(name, config)
      end

      def self.of_type(name)
        CHANNELS.map { |channel| channel.of_type(name) }.compact.first
      end
    end
  end
end
