module DeadlySerious
  module Engine
    class Config
      attr_reader :data_dir, :pipe_dir, :preserve_pipe_dir

      def initialize(data_dir:, pipe_dir:, preserve_pipe_dir:)
        @data_dir = data_dir
        @pipe_dir = pipe_dir
        @preserve_pipe_dir = preserve_pipe_dir
      end

      def setup
        create_data_dir
        create_pipe_dir
      end

      def teardown
        destroy_pipe_dir
      end

      private

      def create_data_dir
        FileUtils.mkdir_p(@data_dir) unless File.exist?(@data_dir)
      end

      def create_pipe_dir
        FileUtils.mkdir_p(@pipe_dir) unless File.exist?(@pipe_dir)
      end

      def destroy_pipe_dir
        return if @preserve_pipe_dir || !File.exist?(@pipe_dir)
        FileUtils.rm_r(@pipe_dir, force: true, secure: true)
      end
    end
  end
end
