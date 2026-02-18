# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser"
require "clickhouse_query_parser/parser"
require "clickhouse_query_parser/tokenizer"

RSpec.describe ClickhouseQueryParser::Parser do
  def parse(sql)
    tokens = ClickhouseQueryParser::Tokenizer.new(sql).tokenize
    described_class.new(tokens).parse
  end

  describe "Date Functions" do
    it "parses simple date functions" do
      sql = "SELECT toYear(created_at) FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :function,
        name: "toYear",
        args: [{ type: :column, name: "created_at" }]
      })
    end

    it "parses functions with multiple arguments" do
      sql = "SELECT dateDiff('day', created_at, updated_at) FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :function,
        name: "dateDiff",
        args: [
          { type: :string, value: "day" },
          { type: :column, name: "created_at" },
          { type: :column, name: "updated_at" }
        ]
      })
    end

    it "parses no-arg functions" do
      sql = "SELECT now() FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :function,
        name: "now",
        args: []
      })
    end

    it "parses INTERVAL arithmetic" do
      sql = "SELECT created_at + INTERVAL 1 DAY FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :binary_op,
        operator: "+",
        left: { type: :column, name: "created_at" },
        right: { type: :interval, value: "1", unit: "DAY" }
      })
    end

    it "parses EXTRACT function" do
      sql = "SELECT EXTRACT(YEAR FROM created_at) FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :function,
        name: "EXTRACT",
        args: [
          { type: :interval_unit, value: "YEAR" },
          { type: :column, name: "created_at" }
        ]
      })
    end
  end
end
