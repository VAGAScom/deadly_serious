require 'spec_helper'
require 'fileutils'
include DeadlySerious::Engine

describe Pipeline do
  DELAY = 0.5 # seconds
  test_file = '/tmp/deadly_serious_test_file'
  result_file = '/tmp/deadly_serious_result_file'

  class TestComponentTime
    def run(delay = nil, readers:, writers:)
      sleep(delay) if delay
    end
  end

  class TestComponentMultiplyBy2
    def run(readers:, writers:)
      reader = JsonIo.new(readers.first)
      writer = JsonIo.new(writers.first)

      reader.each do |(number)|
        writer << [number * 2]
      end
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
      p.spawn_process(TestComponentTime)
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
      p.spawn_process(TestComponentTime, DELAY)
    end
    start = Time.now
    pipeline.run
    finish = Time.now
    expect(finish - start).to be >= DELAY
  end

  it 'kills all children on SIGTERM' do
    pending 'unpredictable'
    start = Time.now

    reader, writer = IO.pipe
    pipeline_id = fork do
      reader.close
      pipeline = Pipeline.new do |p|
        p.spawn_process(TestComponentTime, DELAY)
        p.spawn_process(TestComponentTime, DELAY)
        p.spawn_process(TestComponentTime, DELAY)
        p.spawn_process(TestComponentTime, DELAY)
        writer << p.pids
        writer.close
      end
      pipeline.run
    end
    writer.close
    c1, c2, c3, c4 = eval(reader.readlines.first)
    reader.close
    expect(c1).to be_running
    expect(c2).to be_running
    expect(c3).to be_running
    expect(c4).to be_running
    Process.kill('SIGTERM', pipeline_id)
    Process.wait(pipeline_id)
    finish = Time.now
    expect { Process.wait2(pipeline_id, Process::WNOHANG) }.to raise_error Errno::ECHILD
    expect(finish - start).to be < (DELAY / 4)
  end

  it 'spawns children in parallel' do
    pipeline = Pipeline.new do |p|
      p.spawn_process(TestComponentTime, DELAY)
      p.spawn_process(TestComponentTime, DELAY)
      p.spawn_process(TestComponentTime, DELAY)
      p.spawn_process(TestComponentTime, DELAY)
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

  it 'connects pipes with Component Classes' do
    create_file(test_file, [[1], [2], [3]])
    pipeline = Pipeline.new do |p|
      p.from_file(test_file)
      p.spawn_process(TestComponentMultiplyBy2)
      p.spawn_process(TestComponentMultiplyBy2)
      p.to_file(result_file)
    end
    pipeline.run
    expect(result_file).to have_content [[4], [8], [12]]
  end

  it 'connects pipes with shell commands' do
    create_file(test_file, [[1], [2], [3]])
    pipeline = Pipeline.new do |p|
      p.from_file(test_file)
      p.spawn_command('sed -e s/\[\([0-9]\)\]/_\1_/')
      p.spawn_command('sed -e s/.*/["\0"]/')
      p.to_file(result_file)
    end
    pipeline.run
    expect(result_file).to have_content [['_1_'], ['_2_'], ['_3_']]
  end
end
