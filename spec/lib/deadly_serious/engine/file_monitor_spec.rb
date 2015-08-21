require 'spec_helper'
include DeadlySerious::Engine

describe FileMonitor do
  let(:test_file) { '/tmp/deadly_serious_test/test_file' }
  let(:test_file2) { '/tmp/deadly_serious_test/test_file2' }

  before do
    FileUtils.makedirs('/tmp/deadly_serious_test')
  end

  after do
    FileUtils.rm_rf('/tmp/deadly_serious_test')
  end

  subject { FileMonitor.new(test_file) }

  it 'blocks until file created' do
    t = Thread.new { subject.wait_creation }

    sleep 0.1
    expect(t.alive?).to be_truthy

    `touch #{test_file}`

    sleep 0.1
    expect(t.alive?).to be_falsey

    t.join(1)
  end

  it "don't block if file already exists" do
    `touch #{test_file}`
    t = Thread.new { subject.wait_creation }

    sleep 0.1
    expect(t.alive?).to be_falsey

    t.join(1)
  end

  it 'blocks until file change' do
    `touch #{test_file}`
    t = Thread.new { subject.wait_modification }

    sleep 0.1
    expect(t.alive?).to be_truthy

    File.write(test_file, "test\n")

    sleep 0.1
    expect(t.alive?).to be_falsey

    t.join(1)
  end

  it 'returns modified file' do
    `touch #{test_file}`
    `touch #{test_file2}`
    t = Thread.new { FileMonitor.new(test_file, test_file2).wait_modification }

    sleep 0.1
    expect(t.alive?).to be_truthy

    File.write(test_file2, "test\n")
    t.join(1)
    expect(t.value).to eq test_file2
  end
end