module Cors
  module Utils
    extend self

    HYPHEN = '-'
    HEADERS_JOIN_SEPARATOR = ", "

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

    def prettify_headers_join(
      headers : Array(String),
      separator : (String | Char) = HEADERS_JOIN_SEPARATOR
    ) : String
      String::Builder.build do |builder|
        last_index = headers.size - 1

        headers.each_with_index do |header, i|
          builder << prettify_header(header)

          unless i == last_index
            builder << separator
          end
        end
      end
    end

    def prettify_header(header : String) : String
      capitalize_next = true

      String::Builder.build(header.bytesize) do |builder|
        header.each_char do |char|
          if char == HYPHEN
            builder << HYPHEN
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
