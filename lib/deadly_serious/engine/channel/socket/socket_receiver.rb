class SocketReceiver < SocketChannel

  attr_reader :io_name

  def initialize(host_name, port_number)
    super
    @io_name = format('tcp://%s:%d', host, port.to_i)
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
      yield msg
      @minion.send('') # More msg, pls!
    end
  end

  def close
    @minion.explode if @minion
  end
end