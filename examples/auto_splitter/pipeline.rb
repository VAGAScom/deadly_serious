require 'deadly_serious'

module AutoSplitter
  class Uppercase
    prepend DeadlySerious::Engine::BaseProcess
    def run(packet)
      send packet.upcase
    end
  end
  class Pipeline < DeadlySerious::Engine::Spawner
    def run_pipeline
      spawn_splitter(reader: '>lorem_ipsum.data', writer: 'pipe01.txt', number: 4)
      #spawn_socket_splitter(reader: '>lorem_ipsum.data')
      spawn_processes(Uppercase, reader_pattern: 'pipe01.txt', writers: '>out.txt')
    end
  end
end

if __FILE__ == $0
  AutoSplitter::Pipeline.new.run
end
