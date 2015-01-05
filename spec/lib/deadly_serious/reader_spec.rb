require 'spec_helper'

include DeadlySerious

describe Reader do
  attr_reader :input, :output

  before do
    @input, @output = IO.pipe
  end

  after do
    @input.close if @input && !@input.closed?
    @output.close if @output && !@output.closed?
  end

  describe '#readline' do
    it 'returns received line' do
      reader = Reader.new(input)

      output.puts('test1')
      expect(reader.readline).to eq 'test1'

      output.puts('test2')
      expect(reader.readline).to eq 'test2'
    end

    it 'returns complete lines only' do
      reader = Reader.new(input)

      output.print('tes')
      expect(reader.readline).to be_nil

      output.print("t1\ntest")
      expect(reader.readline).to eq 'test1'
      expect(reader.readline).to be_nil

      output.puts('2')
      expect(reader.readline).to eq 'test2'
    end

    it 'returns nil' do
      reader = Reader.new(input)
      expect(reader.readline).to be_nil
      expect(reader.readline).to be_nil
      output.puts 'test'
      expect(reader.readline).to eq 'test'
      expect(reader.readline).to be_nil
    end

    it 'throws ":io_closed"' do
      reader = Reader.new(input)
      output.close
      expect { reader.readline }.to throw_symbol(:io_closed)
    end

    it 'closes input IO' do
      reader = Reader.new(input)
      output.close

      # Can't close if not call #readline :(
      catch(:io_closed) { reader.readline }
      expect(input).to be_closed
    end
  end
end