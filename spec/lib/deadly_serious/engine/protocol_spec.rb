require 'spec_helper'

include DeadlySerious::Engine

describe Protocol do
  describe '#serialize' do
    it 'serializes empty' do
      p = Protocol.new
      expect(p.serialize('')).to eq ".\n"
    end

    it 'serializes simple fields' do
      class Dummy; attr_accessor :name, :love; end
      p = Protocol.new(:name, :love)

      expect(p.serialize(name: 'test', love: 'letter')).to eq ".\ttest\tletter\n"
      expect(p.serialize(name: 'test')).to eq ".\ttest\t\n"
      expect(p.serialize(love: 'letter')).to eq ".\t\tletter\n"

      dummy = Dummy.new
      dummy.name = 'test'
      expect(p.serialize(dummy)).to eq ".\ttest\t\n"

      expect(p.serialize(['test'])).to eq ".\ttest\t\n"
      expect(p.serialize(['test', 'letter'])).to eq ".\ttest\tletter\n"
    end
  end
  it 'deserializes from String'
end