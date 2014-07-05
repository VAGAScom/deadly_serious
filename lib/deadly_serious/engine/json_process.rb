require 'deadly_serious/engine/json_io'

module DeadlySerious
  module Engine
    # @deprecated Simplifying, simplifying, simplifying
    module JsonProcess
      def run(readers: [], writers: [])
        json_readers = readers.map { |it| JsonIo.new(it) }
        json_writers = writers.map { |it| JsonIo.new(it) }
        super(readers: json_readers, writers: json_writers)
      end
    end
  end
end
