# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser/tokenizer"

RSpec.describe ClickhouseQueryParser::Tokenizer do
  context "with joins and qualified names" do
    it "tokenizes qualified names" do
      sql = "SELECT users.name"
      tokenizer = described_class.new(sql)
      types = tokenizer.tokenize.map { |t| t[:type] }
      expect(types).to eq([:keyword, :identifier, :dot, :identifier])
    end

    it "tokenizes JOIN keywords" do
      sql = "LEFT JOIN profiles ON users.id = profiles.user_id"
      tokenizer = described_class.new(sql)
      values = tokenizer.tokenize.map { |t| t[:value] }
      expect(values).to eq(["LEFT", "JOIN", "profiles", "ON", "users", ".", "id", "=", "profiles", ".", "user_id"])
    end
  end
end
