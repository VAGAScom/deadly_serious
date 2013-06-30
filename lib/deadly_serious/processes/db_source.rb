require 'deadly_serious/engine/json_io'

module DeadlySerious
  module Processes
    module DbSource
      def run(writer)
        run(JsonIo.new(writer))
      end

      def for_each_record(sql)
        connection.select_all(sql).each do |row|
          yield row
        end
      end
    end
  end
end
