require 'spec_helper'

describe DeadlySerious::Engine::JsonIo do
  describe '#each' do
    let(:source) { StringIO.new(%(["uga", 1]\n["buga", 2])) }
    let(:io) { DeadlySerious::Engine::JsonIo.new(source) }

    it 'parses json IO with block' do
      io.each do |(string, number)|
        expect(string).to eq 'uga'
        expect(number).to eq 1
        break
      end
      io.each do |(string, number)|
        expect(string).to eq 'buga'
        expect(number).to eq 2
        break
      end
      io.each do |(string, number)|
        fail 'should have no more lines'
      end
    end

    it 'parses json IO with NO block' do
      result = io.each
      first = result.first
      expect(first[0]).to eq 'uga'
      expect(first[1]).to eq 1

      second = result.first
      expect(second[0]).to eq 'buga'
      expect(second[1]).to eq 2
    end
  end

  describe '#<<' do
    let(:result) { StringIO.new() }
    let(:io) { DeadlySerious::Engine::JsonIo.new(result) }

    it 'stores hashes as json' do
      io << {uga: 1}
      io << {buga: 2}
      expect(result.string).to eq %({"uga":1}\n{"buga":2}\n)
    end

    it 'stores arrays as json' do
      io << ['uga', 1]
      io << ['buga', 2]
      expect(result.string).to eq %(["uga",1]\n["buga",2]\n)
    end

    it 'stores single values as json arrays' do
      io << 'uga'
      io << 1
      expect(result.string).to eq %(["uga"]\n[1]\n)
    end
  end
end
