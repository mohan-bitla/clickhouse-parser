require "spec_helper"
require "clickhouse_query_parser/builder"

RSpec.describe ClickhouseQueryParser::Builder do
  describe "#build" do
    it "builds with LEFT JOIN and qualified columns" do
      hash = {
        type: :select,
        select: [
          { type: :column, name: "name", table: "users" },
          { type: :column, name: "dob", table: "profiles" }
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
      }
      expect(described_class.new(hash).build).to eq("SELECT users.name, profiles.dob FROM users LEFT JOIN profiles ON users.id = profiles.user_id")
    end
  end
end