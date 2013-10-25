require 'deadly_serious'

module ResilienceTest

  class ReadPipe
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      reader.each do |line|
        sleep(0.01)
        writer << line
      end
    end
  end

  class ReadPipeBugged
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first
      x = 0

      reader.each do |line|
        x += 1
        writer << line
        # Die!
        raise 'KABOOOM' if x == 15000
      end
    end
  end

  class Pipeline < DeadlySerious::Engine::Spawner
    include DeadlySerious

    def run_pipeline

      spawn_process(Processes::ResilientSplitter,
                    readers: ['>numbers.txt'],
                    writers: ['pipe_1', 'pipe_2'])


      spawn_process(ReadPipe,
                    readers: ['pipe_1'],
                    writers: ['>output1.txt'])

      spawn_process(ReadPipeBugged,
                    readers: ['pipe_2'],
                    writers: ['>output2.txt'])

    end
  end
end

if __FILE__ == $0
  ResilienceTest::Pipeline.new.run
end
