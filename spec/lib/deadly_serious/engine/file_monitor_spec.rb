require 'spec_helper'
include DeadlySerious::Engine

describe FileMonitor do
  test_file = '/tmp/deadly_serious_test_file'

  before do
    FileUtils.rm_rf(test_file)
  end

  after do
    FileUtils.rm_rf(test_file)
  end

  subject { FileMonitor.new(test_file) }

  it 'blocks until file created' do
    t = Thread.new { subject.wait_file_creation }

    sleep 0.1
    expect(t.alive?).to be_truthy

    `touch #{test_file}`

    sleep 0.1
    expect(t.alive?).to be_falsey

    t.join
  end

  it "don't block if file already exists" do
    `touch #{test_file}`
    t = Thread.new { subject.wait_file_creation }

    sleep 0.1
    expect(t.alive?).to be_falsey

    t.join
  end
end