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
        CHANNELS.each do |channel|
          ch = channel.new_if_match(name, config)
          return ch if ch
        end
      end
    end
  end
end
