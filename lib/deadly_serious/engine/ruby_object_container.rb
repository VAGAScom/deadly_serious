module DeadlySerious
  module Engine
    class RubyObjectContainer
      attr_reader :name

      def initialize(class_or_object, args, process_name, config, reader_names, writers_names)
        @args = args
        @config = config
        @reader_names = reader_names
        @writer_names = writers_names

        @the_object = prepare_object(class_or_object)
        @name = prepare_process_name(@the_object, process_name, reader_names, writers_names)
      end

      def run
        readers = @reader_names.map { |r| Channel.new(r, @config) }
        writers = @writer_names.map { |w| Channel.new(w, @config) }
        @the_object.run(*@args, readers: readers, writers: writers)
      ensure
        writers.each { |w| w.close if w } if writers
        readers.each { |r| r.close if r } if readers
      end

      def finalize
        @the_object.finalize if @the_object.respond_to?(:finalize)
      end

      private

      def prepare_object(class_or_object)
        Class === class_or_object ? class_or_object.new : class_or_object
      end

      def prepare_process_name(the_object, process_name, reader_names, writer_names)
        return process_name if process_name
        name = the_object.respond_to?(:name) ? the_object.name : the_object.to_s
        format('(%s)-->[%s]-->(%s)', reader_names.join(' '), name, writer_names.join(' '))
      end
    end
  end
end