module TelegramProblem
  class Pipeline
    PARAGRAPH_PACKET = 'CONTROL PACKET: paragraph'
    EOL_PACKET = 'CONTROL PACKET: end of line'

    # Break text in words and "END OF LINE" packets (EOL)
    def break_words(file_name)
      writer = []
      open(file_name, 'r').each do |line|
        line.chomp!
        line.scan(/$|\S+/) do |word|
          packet = (word == '' ? EOL_PACKET : word)
          writer << packet
        end
      end
      writer
    end

    # Transforme double "end of line" in "paragraph"
    def eol_to_paragraph(packets)
      writer = []
      last2 = ''
      last1 = ''
      packets.each do |packet|

        #puts "[#{packet}]"

        if packet == EOL_PACKET
          last2 = last1
          last1 = packet
          next
        end

        if last1 == EOL_PACKET && last2 == EOL_PACKET
          writer << PARAGRAPH_PACKET
        end

        writer << packet
        last2 = last1
        last1 = packet
      end
      writer
    end

    # Join words
    def sentence_joiner(file_name, packets)
      line_size = 0
      open(file_name, 'w') do |writer|
        packets.each do |packet|

          #puts "[#{packet}]"

          if packet == PARAGRAPH_PACKET
            writer << "\n\n"
            line_size = 0
            next
          end

          if line_size + packet.size + 1 <= 80
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

    def run
      packets = break_words('data/war_and_peace.txt')
      packets = eol_to_paragraph(packets)
      sentence_joiner('data/output.data', packets)
    end
  end
end

if __FILE__ == $0
  TelegramProblem::Pipeline.new.run
end

