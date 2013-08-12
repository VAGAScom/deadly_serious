require 'deadly_serious'

module TelegramProblem
  LINE_SIZE = 80
  PARAGRAPH_PACKET = 'CONTROL PACKET: paragraph'
  EOL_PACKET = 'CONTROL PACKET: end of line'

  # Break text in words and "END OF LINE" packets (EOL)
  class WordSplitter
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      reader.each do |line|
        line.chomp!
        line.scan(/$|\S+/) do |word|
          packet = (word == '' ? EOL_PACKET : word)
          writer << packet << "\n"
        end
      end
    end
  end

  # Transform double "end of line" in "paragraph"
  class EolToParagraph
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      last2 = ''
      last1 = ''
      reader.each do |packet|
        packet.chomp!

        if packet == EOL_PACKET
          last2 = last1
          last1 = packet
          next
        end

        if last1 == EOL_PACKET && last2 == EOL_PACKET
          writer << PARAGRAPH_PACKET << "\n"
        end

        writer << packet << "\n"
        last2 = last1
        last1 = packet
      end
    end
  end

  # Join words
  class SentenceJoiner
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      line_size = 0

      reader.each do |packet|
        packet.chomp!

        if packet == PARAGRAPH_PACKET
          writer << "\n\n"
          line_size = 0
          next
        end

        if line_size + packet.size + 1 <= LINE_SIZE
          writer << ' ' if line_size > 0
          writer << packet
          line_size += packet.size + 1
        else
          writer << "\n"
          writer << packet
          line_size = packet.size
        end
      end
      writer << "\n" unless line_size == 0
    end
  end

  class Pipeline < DeadlySerious::Engine::Spawner
    def run_pipeline
      spawn_process(WordSplitter,
                    readers: ['>war_and_peace.txt'],
                    writers: ['words_and_eol'])

      spawn_process(EolToParagraph,
                    readers: ['words_and_eol'],
                    writers: ['just_words'])

      spawn_process(SentenceJoiner,
                    readers: ['just_words'],
                    writers: ['>output.data'])
    end
  end
end

if __FILE__ == $0
  TelegramProblem::Pipeline.new.run
end
