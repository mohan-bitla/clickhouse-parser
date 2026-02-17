# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser/parser"
require "clickhouse_query_parser/tokenizer"
require "clickhouse_query_parser/builder"

RSpec.describe ClickhouseQueryParser::Parser do
  def parse(sql)
    tokens = ClickhouseQueryParser::Tokenizer.new(sql).tokenize
    described_class.new(tokens).parse
  end

  describe "#parse" do
    it "parses a simple SELECT *" do
      sql = "SELECT * FROM users"
      result = parse(sql)
      expect(result).to eq({
        type: :select,
        select: [{ type: :star }],
        from: { type: :table, name: "users" }
      })
    end

    it "parses SELECT columns" do
      sql = "SELECT id, name FROM users"
      result = parse(sql)
      expect(result).to eq({
        type: :select,
        select: [
          { type: :column, name: "id" },
          { type: :column, name: "name" }
        ],
        from: { type: :table, name: "users" }
      })
    end

    it "parses WHERE clause" do
      sql = "SELECT * FROM users WHERE id = 1"
      result = parse(sql)
      expect(result[:where]).to eq({
        type: :binary_op,
        operator: "=",
        left: { type: :column, name: "id" },
        right: { type: :number, value: "1" }
      })
    end
    
    it "parses LIMIT" do
      sql = "SELECT * FROM users LIMIT 10"
      result = parse(sql)
      expect(result[:limit]).to eq({ type: :number, value: "10" })
    end

    it "SELECT users.name, users.age FROM users" do
      sql = "SELECT users.name, users.age FROM users"
      result = parse(sql)
      expect(result).to eq({
        type: :select,
        select: [
          { type: :column, name: "name", table: "users" },
          { type: :column, name: "age", table: "users" }
        ],
        from: { type: :table, name: "users" }
      })
    end
  end
end
