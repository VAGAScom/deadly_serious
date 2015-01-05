require 'spec_helper'

include DeadlySerious

describe Reader do
  describe '#check' do
    it 'returns received line' do
      begin
        input, output = IO.pipe
        reader = Reader.new(input)

        output.puts('test1')
        expect(reader.readline).to eq 'test1'

        output.puts('test2')
        expect(reader.readline).to eq 'test2'
      ensure
        input.close
        output.close
      end
    end

    it 'returns complete lines only' do
      begin
        input, output = IO.pipe
        reader = Reader.new(input)

        output.print('tes')
        expect(reader.readline).to be_nil

        output.print("t1\ntest")
        expect(reader.readline).to eq 'test1'
        expect(reader.readline).to be_nil

        output.puts('2')
        expect(reader.readline).to eq 'test2'
      ensure
        input.close
        output.close
      end
    end

    it 'returns nil' do
      begin
        input, output = IO.pipe
        reader = Reader.new(input)
        expect(reader.readline).to be_nil
        expect(reader.readline).to be_nil
        output.puts 'test'
        expect(reader.readline).to eq 'test'
        expect(reader.readline).to be_nil
      ensure
        input.close
        output.close
      end
    end

    it 'throws ":io_closed"' do
      begin
        input, output = IO.pipe
        reader = Reader.new(input)
        output.close
        catch :io_closed do
          reader.readline
          fail 'no throw'
        end
      ensure
        input.close unless input.closed?
      end
    end

    it 'closes input IO' do
      begin
        input, output = IO.pipe
        reader = Reader.new(input)
        output.close

        # Can't close if not check :(
        catch(:io_closed) { reader.readline }
        expect(input).to be_closed
      end
    end
  end
end