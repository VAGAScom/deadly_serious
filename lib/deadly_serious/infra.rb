module DeadlySerious
  class Infra
    def initialize(work_dir)
      @work_dir = work_dir
    end

    def with
      create_infra
      yield
    ensure
      destroy_infra
    end

    private

    def create
      FileUtils.makedirs(@work_dir)
    end

    def destroy
      FileUtils.rm_rf(@work_dir)
    end
  end
end