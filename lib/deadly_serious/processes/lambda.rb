module DeadlySerious
  module Processes
    class Lambda
      attr_reader :name

      def initialize(block, name: 'Lambda')
        @name = name
        @block = block
      end

      def run(readers:, writers:)
        params = @block.parameters
        writer_param = params.any? { |(k, n)| k == :keyreq && n == :writer }
        reader_param = params.any? { |(k, n)| k == :keyreq && n == :reader }

        reader = JsonIo.new(readers.first) if readers.size == 1
        writer = JsonIo.new(writers.first) if writers.size == 1

        if reader_param && writer_param
          unless reader
            fail %(Missing "#{readers.first.filename}", did you provide a reader to lambda?)
          end
          @block.call(reader: reader, writer: writer)
        elsif writer_param && reader
          reader.each do |data|
            @block.call(*data, writer: writer)
          end
        elsif writer_param && !reader
          @block.call(writer: writer)
        elsif reader
          # This is a little "too smarty" for my taste,
          # however, it's awesomely useful. =\
          reader.each do |data|
            result = @block.call(*data)

            # noinspection RubySimplifyBooleanInspection
            if result == true # really TRUE, not thruthy
              # Acts as filter
              writer << data
            elsif result == false || result.nil?
              # Acts as filter
              next
            else
              # Acts as transformation
              writer << result
            end
          end
        else
          @block.call
        end
      end
    end
  end
end