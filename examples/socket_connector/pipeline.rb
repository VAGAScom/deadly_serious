require 'deadly_serious'
class SendPing
  def run(readers: [], writers: [])
    writer = writers.first
    writer << "ping 1\n"
    writer << "ping 2\n"
    writer << "ping 3\n"
  end
end

class Echo
  def run(readers: [], writers: [])
    reader = readers.first

    reader.each { |line| puts line }
  end
end

class Pipeline < DeadlySerious::Engine::Spawner
  def run_pipeline
    spawn_process(SendPing,
                  writers: ['localhost:6666'])

    spawn_process(Echo,
                  readers: ['localhost:6666'])
  end
end

Pipeline.new.run if __FILE__ == $0
