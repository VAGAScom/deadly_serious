require 'spec_helper'
include DeadlySerious::Engine

describe SocketChannel do
  let(:test_config) do
    Config.new(data_dir: "/tmp/test_deadly_serious#{Process.pid}",
               pipe_dir: "/tmp/test_deadly_serious#{Process.pid}",
               preserve_pipe_dir: false)
  end

  matcher :produce_a do |expected|
    subject = nil
    match do |actual|
      begin
        subject = Channel.new(actual, test_config)
        subject.is_a?(expected)
      ensure
        subject.close if subject
      end
    end
    failure_message do
      "but was a #{subject.class.name}"
    end
  end

  describe 'sink' do
    let(:snd) { '>}' }
    let(:rcv) { '<}' }

    def send_msg(*msgs, port: 5555)
      fork do
        sender = Channel.new("#{snd}localhost:#{port}", nil)
        msgs.each { |m| sender << m }
        sender.close
      end
    end

    it 'detects sender by its name' do
      expect("#{snd}localhost:5555").to produce_a SocketSinkSendr
    end

    it 'detects receiver by its name' do
      expect("#{rcv}localhost:5555").to produce_a SocketSinkRecvr
    end

    it 'connect two simple processes' do
      begin
        send_msg(1, 2)
        receiver = Channel.new("#{rcv}localhost:5555", nil)
        stream = receiver.each
        expect(stream.next).to eq '1'
        expect(stream.next).to eq '2'
      ensure
        receiver.close if receiver
      end
    end
  end

  describe 'ventilator' do
    let(:snd) { '>{' }
    let(:rcv) { '<{' }

    def send_msg(*msgs, port: 5555)
      fork do
        sender = Channel.new("#{snd}localhost:#{port}", nil)
        msgs.each { |m| sender << m }
        sender.close
      end
    end

    it 'detects sender by its name' do
      expect("#{snd}localhost:5555").to produce_a SocketVentSendr
    end

    it 'detects receiver by its name' do
      expect("#{rcv}localhost:5555").to produce_a SocketVentRecvr
    end

    it 'connect two simple processes' do
      begin
        send_msg(1, 2)
        receiver = Channel.new("#{rcv}localhost:5555", nil)
        stream = receiver.each
        expect(stream.next).to eq '1'
        expect(stream.next).to eq '2'
      ensure
        receiver.close if receiver
      end
    end

    it 'has the same ZMQ context for multiple channels' do
      c1 = Channel.new("#{rcv}localhost:5555", nil)
      ctx1 = c1.context

      c2 = Channel.new("#{snd}localhost:5556", nil)
      ctx2 = c2.context

      expect(ctx1).to eq ctx2
      c1.close
      c2.close
    end

    it 'has different contexts when open/close twice' do
      c1 = Channel.new("#{rcv}localhost:5555", nil)
      ctx1 = c1.context
      c1.close

      c2 = Channel.new("#{snd}localhost:5556", nil)
      ctx2 = c2.context
      c2.close

      expect(ctx1).not_to eq ctx2
    end

    it 'clear ZMQ context on finish a single channel' do
      send_msg(1)
      channel = Channel.new("#{rcv}localhost:5555", nil)
      channel.each {}
      ctx = channel.context
      channel.close
      expect do
        ctx.bind(:PUSH, 'tcp://*:5556')
      end.to raise_error(ZMQ::Error, /has been destroyed/)
    end

    it 'clear ZMQ context on finish all channels' do
      channel1 = Channel.new("#{rcv}localhost:5555", nil)
      channel2 = Channel.new("#{rcv}localhost:5556", nil)

      ctx = channel1.context

      channel1.close
      expect do
        ctx.bind(:PUSH, 'tcp://*:5557')
      end.not_to raise_error

      channel2.close
      expect do
        ctx.bind(:PUSH, 'tcp://*:5558')
      end.to raise_error(ZMQ::Error, /has been destroyed/)
    end

    it 'does load balancing' do
      send_msg(1, 2, 3)
      channel1 = Channel.new("#{rcv}localhost:5555", nil)
      channel2 = Channel.new("#{rcv}localhost:5555", nil)

      c1 = channel1.each
      c2 = channel2.each

      expect(c1.next).to eq '1'
      expect(c2.next).to eq '2'
      expect(c1.next).to eq '3'

      channel1.close
      channel2.close
    end
  end
end