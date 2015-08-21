class MasterMind
  attr_reader :factory

  def self.new_instance
    pid = Process.pid
    if @master.nil? || @master[:pid] != pid
      @master = {pid: pid, master: self.new}
    end
    @master[:master]
  end

  def initialize
    @factory = ZMQ::Context.new
    @counter = 1
    @minions = []
  end

  def spawn_minion
    minion_brain = yield(@factory, @counter)
    @counter += 1
    Minion.new(self, minion_brain).tap { |m| @minions << m }
  rescue ZMQ::Error => e
    raise if e.message !~ /has been destroyed/
    @factory = ZMQ::Context.new
    retry
  end

  def destroy_body_of(minion)
    @minions.delete(minion)
    suicide if @minions.empty?
  end

  private

  def suicide
    @factory.destroy
  end
end