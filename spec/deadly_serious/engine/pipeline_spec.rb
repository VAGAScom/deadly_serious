require 'spec_helper'
require 'fileutils'
include DeadlySerious::Engine

describe Pipeline do
  DELAY = 0.5 # seconds
  test_file = '/tmp/deadly_serious_test_file'
  result_file = '/tmp/deadly_serious_result_file'

  class TestComponent
    def run(delay = nil, readers:, writers:)
      sleep(delay) if delay
    end
  end

  before do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
  end

  after do
    FileUtils.rm_rf(test_file)
    FileUtils.rm_rf(result_file)
  end

  it "runs a Component in it's own children process" do
    pid = nil
    executed = false
    pipeline = Pipeline.new do |p|
      executed = true
      expect(p.pids.size).to eq 0
      p.spawn_process(TestComponent)
      expect(p.pids.size).to eq 1

      pid, _ = p.pids
      expect(pid).to be_running
      expect(pid).to be_children_of Process.pid
    end
    expect(executed).to be false
    pipeline.run
    expect(executed).to be true
    expect(pid).not_to be_running
  end

  it 'waits until all children complete' do
    pipeline = Pipeline.new do |p|
      p.spawn_process(TestComponent, DELAY)
    end
    start = Time.now
    pipeline.run
    finish = Time.now
    expect(finish - start).to be >= DELAY
  end

  it 'spawns children in parallel' do
    pipeline = Pipeline.new do |p|
      p.spawn_process(TestComponent, DELAY)
      p.spawn_process(TestComponent, DELAY)
      p.spawn_process(TestComponent, DELAY)
      p.spawn_process(TestComponent, DELAY)
    end
    start = Time.now
    pipeline.run
    finish = Time.now
    # If not in parallel, it would run in 4 * DELAY,
    # but it runs in less than half that time.
    expect(finish - start).to be >= DELAY
    expect(finish - start).to be <= 2 * DELAY
  end

  it 'spawns linux commands' do
    pipeline = Pipeline.new do |p|
      p.from_file(test_file)
      p.spawn_command('cat')
      p.to_file(result_file)
    end
    expect(test_file).to_not exists
    pipeline.run
    expect(test_file).to exists
  end
end