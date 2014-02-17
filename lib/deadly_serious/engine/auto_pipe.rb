class DeadlySerious::Engine::AutoPipe
  TEMPLATE = '%s.connection.%04d'

  def initialize
    @net_id = 0
    @connection_stack = []
    @counter = Hash.new { |h, k| h[k.to_sym] = 0}
  end

  def on_subnet
    @net_id += 1
    @connection_stack << sprintf('%04d', @net_id)
    yield
  ensure
    @connection_stack.pop
  end

  def net_id
    (@connection_stack.last || 'top').to_sym
  end

  def counter
    @counter[net_id]
  end

  def next
    advance_counter
    last
  end

  def last
    sprintf(TEMPLATE, net_id, counter)
  end

  private
  def advance_counter
    @counter[net_id] += 1
  end
end
