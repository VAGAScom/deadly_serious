require 'deadly_serious'

RSpec::Matchers.define :be_running do
  message = nil
  match do |pid|
    begin
      Process.kill(0, pid)
      return true
    rescue Errno::EPERM # changed uid
      message = "No permission to query #{pid}!";
    rescue Errno::ESRCH
      message = "PID #{pid} is NOT running."; # or zombied
    rescue
      message = "Unable to determine status for PID #{pid} : #{$!}"
    end
    return false
  end
  failure_message { |pid| message }
end

RSpec::Matchers.define :be_children_of do |ppid|
  match do |pid|
    ppid == `ps -p #{pid} -o ppid=`.to_i
  end
  failure_message do |pid|
    "expected PID #{pid} to be children of PPID #{ppid}"
  end
end

RSpec::Matchers.define :exists do
  match do |file_name|
    File.exist?(file_name)
  end
end

RSpec::Matchers.define :have_content do |expected|
  result = nil
  match do |file_name|
    result = open(file_name, 'r') do |f|
      f.map { |line| JSON.parse(line) }
    end
    result == expected
  end
  failure_message do |file_name|
    %(expected "#{file_name}" to have content "#{expected}", but was "#{result}")
  end
end
