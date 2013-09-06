require 'deadly_serious'

module AutoSplitter
  class Pipeline < DeadlySerious::Engine::Spawner
    def run_pipeline
      #spawn_splitter(reader: '>lorem_ipsum.data', writer: '>out01.txt', number: 4)
      spawn_socket_splitter(reader: '>lorem_ipsum.data')
    end
  end
end

if __FILE__ == $0
  AutoSplitter::Pipeline.new.run
end
