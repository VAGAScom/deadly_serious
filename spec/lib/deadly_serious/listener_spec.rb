require 'spec_helper'

include DeadlySerious

describe Listener do
  it 'executes block when receive line' do
    child_reader, parent_writer = IO.pipe
    parent_reader, child_writer = IO.pipe
    pid = fork do
      begin
        parent_reader.close
        parent_writer.close
        listener = Listener.new
        listener.on_receive_from(child_reader) do |line|
          child_writer.puts("echo: #{line}")
        end
        listener.listen
      ensure
        child_writer.close
      end
    end
    child_reader.close
    child_writer.close

    parent_writer.puts 'test1'
    parent_writer.puts 'test2'
    parent_writer.flush
    parent_writer.close

    expect(parent_reader.gets.chomp).to eq 'echo: test1'
    expect(parent_reader.gets.chomp).to eq 'echo: test2'
    parent_reader.close

    Process.waitpid(pid)
  end
end