require 'deadly_serious'

module TelegramProblem
  PARAGRAPH_PACKET = 'CONTROL PACKET: paragraph'
  EOL_PACKET = 'CONTROL PACKET: end of line'

  # Break text in words and "END OF LINE" packets (EOL)
  class WordSplitter
    prepend DeadlySerious::Engine::PushPopSend
    def run(packet)
      packet.scan(/$|\S+/) do |word|
        send(word == '' ? EOL_PACKET : word)
      end
    end
  end

  # Transform double "end of line" in "paragraph"
  class EolToParagraph
    prepend DeadlySerious::Engine::PushPopSend
    def run(packet)
      if packet == EOL_PACKET
        push packet
        return
      end

      if top_stack(2) == [EOL_PACKET, EOL_PACKET]
        send PARAGRAPH_PACKET
      end

      send packet
      reset_stack
    end
  end

  # Join words
  class SentenceJoiner
    prepend DeadlySerious::Engine::PushPopSend

    def initialize
      @line = ''
    end

    def run(packet)
      if packet == PARAGRAPH_PACKET
        send @line
        send # Empty packet means "enter"
        @line = ''
        return
      end

      if @line.size + packet.size + 1 <= 80
        @line << ' ' if @line.size > 0
        @line << packet
      else
        send @line
        @line = packet
      end
    end
  end

  class Pipeline < DeadlySerious::Engine::Spawner
    include DeadlySerious
    def run_pipeline
      spawn_process(WordSplitter, readers: ['>war_and_peace.txt'], writers: ['words_and_eol'])
      spawn_process(EolToParagraph, readers: ['words_and_eol'], writers: ['just_words'])
      spawn_process(SentenceJoiner, readers: ['just_words'], writers: ['>output.data'])
    end
  end
end

if __FILE__ == $0
  TelegramProblem::Pipeline.new.run
end
