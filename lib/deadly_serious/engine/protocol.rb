module DeadlySerious
  module Engine
    # It represents a contract between components.
    #
    # It was created to turn data manipulation easy between components,
    # either Ruby components or command lines.
    #
    # The String protocol is:
    # metadata.metadata.metadata.\tdata\tdata\tdata
    #
    # For example, record with no metadata and 2 fields ("Uga Buga" and "123")
    # .\tUga Buga\t123
    #
    # An "open bracket"
    # open.\tSomeType
    class Protocol
      def initialize(*simple_fields)
        @field_definition = simple_fields.map { |f| [f, String] }.to_h
        @field_keys = @field_definition.keys
      end

      def serialize(data)
        data = @field_definition.each_with_object(['.']) do |(k, v), rslt|
          rslt << (extract(data, k))
        end
        format("%s\n", data.join("\t"))
      end

      private

      def extract(data, key)
        case data
          when Array
            data[@field_keys.index(key)]
          else
            data.respond_to?(:[]) ? data[key] : data.send(key.to_sym)
        end
      end
    end
  end
end