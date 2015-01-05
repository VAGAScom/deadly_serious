require 'spec_helper'

include DeadlySerious

describe Writer do
  attr_reader :input, :output

  before do
    @input, @output = IO.pipe
  end

  after do
    @input.close if @input && !@input.closed?
    @output.close if @output && !@output.closed?
  end

  describe '#puts' do
    it 'sends data' do
      writer = Writer.new(output)
      writer.puts('uga')
      expect(input.gets.chomp).to eq 'uga'
      writer.puts('Muga')
      expect(input.gets.chomp).to eq 'Muga'
      writer.puts('Atuga')
      writer.puts('Chutuga')
      expect(input.gets.chomp).to eq 'Atuga'
      expect(input.gets.chomp).to eq 'Chutuga'
    end

    it 'throws ":io_closed"' do
      writer = Writer.new(output)
      input.close
      expect { writer.puts('uga') }.to throw_symbol(:io_closed)
    end

    it 'closes input IO' do
      writer = Writer.new(output)
      input.close
      catch(:io_closed) { writer.puts('uga') }
      expect(output).to be_closed
    end
  end
end