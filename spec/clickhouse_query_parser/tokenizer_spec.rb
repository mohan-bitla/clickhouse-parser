# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser/tokenizer"

RSpec.describe ClickhouseQueryParser::Tokenizer do
  describe "#tokenize" do
    it "tokenizes a simple SELECT statement" do
      sql = "SELECT id, name FROM users"
      tokenizer = described_class.new(sql)
      ids = tokenizer.tokenize.map { |t| t[:type] }
      values = tokenizer.tokenize.map { |t| t[:value] }

      expect(ids).to eq([:keyword, :identifier, :comma, :identifier, :keyword, :identifier])
      expect(values).to eq(["SELECT", "id", ",", "name", "FROM", "users"])
    end

    it "tokenizes numbers and strings" do
      sql = "WHERE id = 1 AND name = 'Alice'"
      tokenizer = described_class.new(sql)
      expect(tokenizer.tokenize).to include(
        { type: :identifier, value: "id" },
        { type: :operator, value: "=" },
        { type: :number, value: "1" },
        { type: :keyword, value: "AND" },
        { type: :string, value: "Alice" }
      )
    end

    it "handles stars and function calls" do
      sql = "SELECT count(*)"
      tokenizer = described_class.new(sql)
      types = tokenizer.tokenize.map { |t| t[:type] }
      expect(types).to eq([:keyword, :identifier, :lparen, :star, :rparen])
    end

     it "handles symbols" do
       sql = "SELECT :symbol"
       tokenizer = described_class.new(sql)
       types = tokenizer.tokenize.map { |t| t[:type] }
       expect(types).to eq([:keyword, :symbol])
     end
  end
end
