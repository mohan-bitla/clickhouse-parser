# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser"

RSpec.describe ClickhouseQueryParser::Builder do
  describe "Date Functions" do
    it "builds simple date functions" do
      hash = {
        type: :select,
        select: [{
          type: :function,
          name: "toYear",
          args: [{ type: :column, name: "created_at" }]
        }],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT toYear(created_at) FROM users")
    end

    it "builds INTERVAL arithmetic" do
      hash = {
        type: :select,
        select: [{
          type: :binary_op,
          operator: "+",
          left: { type: :column, name: "created_at" },
          right: { type: :interval, value: "1", unit: "DAY" }
        }],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT created_at + INTERVAL 1 DAY FROM users")
    end

    it "builds EXTRACT function" do
      hash = {
        type: :select,
        select: [{
          type: :function,
          name: "EXTRACT",
          args: [
            { type: :interval_unit, value: "YEAR" },
            { type: :column, name: "created_at" }
          ]
        }],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT EXTRACT(YEAR FROM created_at) FROM users")
    end
  end
end
