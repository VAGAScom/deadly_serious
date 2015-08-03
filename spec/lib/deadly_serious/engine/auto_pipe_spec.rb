require 'spec_helper'
include DeadlySerious::Engine

describe AutoPipe do
  subject { AutoPipe.new }
  describe '#last' do
    it 'returns last writer' do
      subject.next
      expect(subject.last).to eq 'pipe.0001'
    end

    it 'returns nil if no last writer' do
      expect(subject.last).to be_nil
    end
  end

  describe '#next' do
    it 'returns next writer name' do
      expect(subject.next).to eq 'pipe.0001'
      expect(subject.next).to eq 'pipe.0002'
    end
  end

  describe '#on_subnet' do
    it 'creates "subnames" to avoid conflicts' do
      subject.next
      subject.on_subnet do
        expect(subject.next).to eq 'pipe.0001.0001'
        expect(subject.last).to eq 'pipe.0001.0001'
        expect(subject.next).to eq 'pipe.0001.0002'
        subject.on_subnet do
          expect(subject.next).to eq 'pipe.0001.0002.0001'
        end
      end
      subject.next
      subject.on_subnet do
        expect(subject.next).to eq 'pipe.0002.0001'
      end
    end
  end
end