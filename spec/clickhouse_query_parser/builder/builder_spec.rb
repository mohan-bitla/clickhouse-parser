# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser/builder"

RSpec.describe ClickhouseQueryParser::Builder do
  describe "#build" do
    it "builds a simple SELECT *" do
      hash = {
        type: :select,
        select: [{ type: :star }],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT * FROM users")
    end

    it "builds SELECT with columns and WHERE" do
      hash = {
        type: :select,
        select: [{ type: :column, name: "id" }, { type: :column, name: "name" }],
        from: { type: :table, name: "users" },
        where: {
          type: :binary_op,
          operator: "=",
          left: { type: :column, name: "id" },
          right: { type: :number, value: "1" }
        }
      }
      expect(described_class.new(hash).build).to eq("SELECT id, name FROM users WHERE id = 1")
    end

    it "builds with GROUP BY and ORDER BY" do
      hash = {
        type: :select,
        select: [{ type: :column, name: "age" }, { type: :function, name: "count", args: [{ type: :star }]}],
        from: { type: :table, name: "users" },
        group_by: [{ type: :column, name: "age" }],
        order_by: [{ expr: { type: :column, name: "age" }, direction: :desc }],
        limit: { type: :number, value: "10" }
      }
      expect(described_class.new(hash).build).to eq("SELECT age, count(*) FROM users GROUP BY age ORDER BY age DESC LIMIT 10")
    end

    it "builds with qualified columns" do
      hash = {
        type: :select,
        select: [
          { type: :column, name: "name", table: "users" },
          { type: :column, name: "age", table: "users" }
        ],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT users.name, users.age FROM users")
    end
  end
end
