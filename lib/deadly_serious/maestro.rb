module DeadlySerious
  class Maestro
    def initialize(pid: Process.pid)
      @pid = pid
      @work_dir = sprintf('/tmp/deadly_serious/%s', @pid)
      @processes = []
      yield self if block_given?
    end

    def register(&block)
      @processes << Engine::ProcessWatcher.new(&block)
    end

    def while_running(&block)
      @while_running = block
    end

    def call
      @processes.each { |p| p.call }
      @while_running.call if @while_running
      @processes.each { |p| p.join }
    end

    def create_infra
      FileUtils.makedirs(@work_dir)
    end

    def destroy_infra
      FileUtils.rm_rf(@work_dir)
    end
  end
end