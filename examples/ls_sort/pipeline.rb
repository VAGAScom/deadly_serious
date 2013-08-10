require 'deadly_serious'

module LsSort
  class Pipeline < DeadlySerious::Engine::Spawner
    def run_pipeline
      spawn_command('ls ~ > ((ls_test))')
      spawn_command('cat ((ls_test)) | sort > ((>put_here))')
    end
  end
end

if __FILE__ == $0
  LsSort::Pipeline.new.run
end
