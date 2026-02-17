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
    
    it "SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id" do
      sql = "SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id"
      result = parse(sql)
      expect(result).to eq({
        type: :select,
        select: [
          { type: :column, name: "name", table: "users" },
          { type: :column, name: "age", table: "users" },
          { type: :column, name: "dob", table: "profile" }
        ],
        from: { type: :table, name: "users" },
        join: {
          type: :left_join,
          table: { type: :table, name: "profiles" },
          on: {
            type: :binary_op,
            operator: "=",
            left: { type: :column, name: "id", table: "users" },
            right: { type: :column, name: "user_id", table: "profiles" }
          }
        }
      })
    end

  end
end