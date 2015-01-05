module DeadlySerious
  module Engine
    class ProcessWatcher
      def initialize(&block)
        @block = block
      end

      # Check if the "#start" was called.
      #
      # return (Integer) the child process id or
      #   nil if not started.
      def started?
        @pid
      end

      # Check if the child process is running.
      #
      # return (true|false)
      def alive?
        return false unless @pid
        # This avoid wrong status due zombie processes
        collect_status
        Process.getpgid(@pid)
      rescue Errno::ESRCH, Errno::ECHILD
        false
      else
        true
      end

      def dead?
        !alive?
      end

      def start
        collect_status if started?
        fail 'Still running' if alive?
        @pid = fork &@block
      end
      alias :call :start

      def finish!(timeout = 1)
        return if !started? || dead?
        term!
        Timeout::timeout(timeout) { join }
      rescue Timeout::Error
        # Can we have a zombie process if "kill" does not work?
        kill!
      end

      def term!
        send_signal('TERM')
      end

      def kill!
        send_signal('KILL')
      end

      def send_signal(signal)
        return unless @pid
        Process.kill(signal, @pid) rescue nil
      end

      def join
        Process.waitpid(@pid) if @pid
      rescue Errno::ECHILD
        # Ignore, child finished
      end

      def to_s
        "Process (#{@pid})"
      end

      private

      def collect_status
        Process.wait(@pid, Process::WNOHANG) if @pid
      end
    end
  end
end