require 'spec_helper'
include DeadlySerious::Engine

# Those tests can break if your machine is under heavy load :(
describe ProcessWatcher do
  let(:tmp_file) { '/tmp/process_watcher_test_file' }

  before do
    FileUtils.rm_rf tmp_file
    @p_time = ProcessWatcher.new do
      `sleep 0.25`
    end
  end

  after do
    FileUtils.rm_rf tmp_file
  end

  describe '#start' do
    it 'runs a block as a child process (in parallel)' do
      p = ProcessWatcher.new do
        `sleep 0.1; touch #{tmp_file}`
      end

      expect(File.exist?(tmp_file)).to be_falsey
      p.start

      expect(File.exist?(tmp_file)).to be_falsey
      sleep 0.25
      expect(File.exist?(tmp_file)).to be_truthy
    end
  end

  describe '#started?' do
    it 'answers if the child process was once started' do
      expect(@p_time.started?).to be_falsey
      @p_time.start
      sleep 0.1
      expect(@p_time.started?).to be_truthy
      sleep 0.25
      expect(@p_time.started?).to be_truthy
    end
  end

  describe '#alive?' do
    it 'answers if the child process is still running' do
      expect(@p_time.alive?).to be_falsey
      @p_time.start
      sleep 0.1
      expect(@p_time.alive?).to be_truthy
      sleep 0.5
      expect(@p_time.alive?).to be_falsey
    end
    it 'does not wait for the child process' do
      @p_time.start
      start = Time.now
      @p_time.alive?
      finish = Time.now
      expect(finish - start).to be < 0.25
    end
  end

  describe '#send_signal' do
    it 'sends signals to child process' do
      p = ProcessWatcher.new do
        Signal.trap('USR1') do
          `touch #{tmp_file}`
        end
        sleep 0.25
      end
      p.start
      sleep 0.05
      expect(File.exist?(tmp_file)).to be_falsey
      p.send_signal('USR1')
      sleep 0.05 # Time to execute
      expect(File.exist?(tmp_file)).to be_truthy
    end
  end

  describe '#finish!' do
    it 'asks child process to finish (SIGTERM)' do
      @p_time.start
      sleep 0.05
      expect(@p_time.alive?).to be_truthy
      @p_time.finish!
      sleep 0.05
      expect(@p_time.alive?).to be_falsey
    end
    it 'force child process to finish after timeout (SIGKILL)' do
      p = ProcessWatcher.new do
        Signal.trap('TERM') do
          # ignore "TERM" signal
        end
        sleep 1
      end
      p.start
      sleep 0.05
      expect(p.alive?).to be_truthy
      p.finish!(0.1)
      sleep 0.05 # Time to kill
      expect(p.alive?).to be_falsey
    end
  end

  describe '#join' do
    it 'blocks until the child process to finish' do
      @p_time.start
      start = Time.now
      @p_time.join
      finish = Time.now
      expect(finish - start).to be >= 0.25
    end
    it 'returns immediatelly if child process already finished' do
      @p_time.start
      sleep 0.3
      start = Time.now
      @p_time.join
      finish = Time.now
      expect(finish - start).to be <= 0.1
    end
  end
end