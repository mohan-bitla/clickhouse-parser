# frozen_string_literal: true

require_relative "clickhouse_query_parser/version"
require_relative "clickhouse_query_parser/tokenizer"
require_relative "clickhouse_query_parser/parser"
require_relative "clickhouse_query_parser/builder"

module ClickhouseQueryParser
  class Error < StandardError; end

  def self.parse(sql)
    tokens = Tokenizer.new(sql).tokenize
    Parser.new(tokens).parse
  end

  def self.build(hash)
    Builder.new(hash).build
  end
end
