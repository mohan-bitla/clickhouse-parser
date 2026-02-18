# frozen_string_literal: true

module ClickhouseQueryParser
  require "strscan"
  class Tokenizer
    TOKEN_REGEX = /
      (?<string>'[^']*')|
      (?<number>\d+(\.\d+)?)|
      (?<symbol>:[a-zA-Z_]\w*)|
      (?<keyword>\b(SELECT|FROM|WHERE|AND|OR|GROUP|BY|ORDER|LIMIT|INSERT|INTO|VALUES|CREATE|TABLE|PREWHERE|HAVING|FORMAT|ASC|DESC|LEFT|RIGHT|INNER|OUTER|JOIN|ON|UNION|ALL|INTERVAL|EXTRACT|YEAR|MONTH|DAY|HOUR|MINUTE|SECOND|WEEK|QUARTER)\b)|
      (?<dot>\.)|
      (?<identifier>[a-zA-Z_]\w*|"[^"]*")|
      (?<operator>!=|>=|<=|<>|=|>|<|\+|-|\/|%)|
      (?<comma>,)|
      (?<star>\*)|
      (?<lparen>\()|
      (?<rparen>\))|
      (?<whitespace>\s+)
    /ix

    def initialize(sql)
      @sql = sql
    end

    def tokenize
      tokens = []
      scanner = StringScanner.new(@sql)

      until scanner.eos?
        match = scanner.scan(TOKEN_REGEX)
        if match
          if scanner[:whitespace]
            # ignore
          elsif scanner[:string]
            tokens << { type: :string, value: scanner[:string][1..-2] }
          elsif scanner[:number]
            tokens << { type: :number, value: scanner[:number] }
           elsif scanner[:symbol]
            tokens << { type: :symbol, value: scanner[:symbol] }
          elsif scanner[:keyword]
            tokens << { type: :keyword, value: scanner[:keyword].upcase }
          elsif scanner[:identifier]
            value = scanner[:identifier]
            value = value[1..-2] if value.start_with?('"')
            tokens << { type: :identifier, value: value }
          elsif scanner[:operator]
            tokens << { type: :operator, value: scanner[:operator] }
          elsif scanner[:dot]
            tokens << { type: :dot, value: "." }
          elsif scanner[:comma]
            tokens << { type: :comma, value: "," }
          elsif scanner[:star]
            tokens << { type: :star, value: "*" }
          elsif scanner[:lparen]
            tokens << { type: :lparen, value: "(" }
          elsif scanner[:rparen]
            tokens << { type: :rparen, value: ")" }
          end
        else
          raise ClickhouseQueryParser::Error, "Unexpected character at position #{scanner.pos}: #{scanner.string[scanner.pos]}"
        end
      end

      tokens
    end
  end
end
