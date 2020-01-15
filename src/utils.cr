module Cors
  module Utils
    extend self

    def normalize_header(header : String) : String
      String::Builder.build(header.bytesize) do |builder|
        header.each_char do |char|
          if char.whitespace?
            next
          end

          builder << char.downcase
        end
      end
    end

    def parse_headers(headers : String) : Array(String)
      # TODO: Optimize?
      headers.split(',').map { |h| normalize_header(h) }
    end

    def prettify_header(header : String) : String
      capitalize_next = true

      String::Builder.build(header.bytesize) do |builder|
        header.each_char do |char|
          if char == '-'
            builder << char
            capitalize_next = true

            next
          end

          if capitalize_next
            builder << char.upcase
            capitalize_next = false
          else
            builder << char
          end
        end
      end
    end
  end
end
