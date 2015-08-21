class SocketSender < SocketChannel

  attr_reader :io_name

  def initialize(host_name, port_number)
    super
    @io_name = format('tcp://*:%d', port.to_i)
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
    @minion.explode if @minion
  end
end