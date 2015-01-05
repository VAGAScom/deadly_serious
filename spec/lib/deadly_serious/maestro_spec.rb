require 'spec_helper'
include DeadlySerious

describe Maestro do
  # describe 'basic' do
  #   Maestro.new do |m|
  #     m.source(:myfile, '')
  #     m.step(AnObjectToProc)
  #
  #     m.register(:blah, SomeClass)
  #     m.register(:bleh) { |x, y| } # Transforming
  #     m.register(:blih) { |x, y, writer:| } # Filtering
  #     m.register(:bloh) { |reader:, writer:| } # Fold
  #     m.pipe(:blah, :bleh)
  #     m.pipe(:bleh, :blih)
  #     m.pipe(:blih, :bloh)
  #     m.pipe(:blah, :bleh, :blih, :bloh)
  #     m.split(:blah).to(:bleh, :blih)
  #     m.join(:bleh, :blih).to(:bloh)
  #   end
  # end

  describe '#call' do
    it 'runs registered code' do
      file = '/tmp/deadly_serious/tmp_file'
      maestro = Maestro.new do |m|
        m.register { touch file }
      end
      expect(file).not_to exists
      maestro.call
      expect(file).to exists
    end

    it 'creates and destroys work dir' do
      parent_read, child_write = IO.pipe
      maestro = Maestro.new(pid: 123456) do |m|
        m.register do
          begin
            parent_read.close
            child_write.puts('ok')
            child_write.print('o')
            sleep 0.25
            child_write.puts('k')
            child_write.puts('bye')
          ensure
            child_write.close
          end
        end
      end
      maestro.while_running do
        child_write.close

        event = ->(data) do
          puts ">#{data}"
          throw :out if data == 'bye'
        end

        selector = NIO::Selector.new
        monitor = selector.register(parent_read, :r)

        buffer = ''
        monitor.value = -> do
          begin
            buffer << monitor.io.read_nonblock(4096)
            while match = buffer.match(/[^\n]+\n/)
              event.yield match.to_s.chomp

              buffer = match.post_match
            end
          rescue EOFError
            throw :closed
          end
        end

        catch :out do
          catch :closed do
            selector.select { |m| m.value.call } while true
          end
          p 'closed'
        end

      end
      maestro.call
    end
  end

  describe '#create_infra' do
    it 'creates work dir' do
      m = Maestro.new(pid: 123456)
      m.create_infra
      expect('/tmp/deadly_serious/123456').to exists
    end
  end

  describe '#destroy_infra' do
    it 'destroys work dir' do
      FileUtils.makedirs('/tmp/deadly_serious/123456')
      expect('/tmp/deadly_serious/123456').to exists
      m = Maestro.new(pid: 123456)
      m.destroy_infra
      expect('/tmp/deadly_serious/123456').not_to exists
    end
  end
end