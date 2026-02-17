# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser/parser"
require "clickhouse_query_parser/tokenizer"

RSpec.describe ClickhouseQueryParser::Parser do
  def parse(sql)
    tokens = ClickhouseQueryParser::Tokenizer.new(sql).tokenize
    described_class.new(tokens).parse
  end

  describe "#parse extended" do
    it "parses functions" do
      sql = "SELECT count(*) FROM users"
      result = parse(sql)
      expect(result[:select]).to eq([
        { type: :function, name: "count", args: [{ type: :star }] }
      ])
    end

    it "parses GROUP BY" do
      sql = "SELECT age FROM users GROUP BY age"
      result = parse(sql)
      expect(result[:group_by]).to eq([
        { type: :column, name: "age" }
      ])
    end

    it "parses ORDER BY" do
      sql = "SELECT * FROM users ORDER BY age DESC, id ASC"
      result = parse(sql)
      expect(result[:order_by]).to eq([
        { expr: { type: :column, name: "age" }, direction: :desc },
        { expr: { type: :column, name: "id" }, direction: :asc }
      ])
    end
  end
end
