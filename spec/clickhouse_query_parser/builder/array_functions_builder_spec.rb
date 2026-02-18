# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser"

RSpec.describe ClickhouseQueryParser::Builder do
  describe "Array Functions" do
    it "builds array literals" do
      hash = {
        type: :select,
        select: [{
          type: :array,
          values: [
            { type: :number, value: "1" },
            { type: :number, value: "2" }
          ]
        }]
      }
      expect(described_class.new(hash).build).to eq("SELECT [1, 2]")
    end

    it "builds array element access" do
      hash = {
        type: :select,
        select: [{
          type: :array_access,
          column: { type: :column, name: "arr" },
          index: { type: :number, value: "1" }
        }],
        from: { type: :table, name: "users" }
      }
      expect(described_class.new(hash).build).to eq("SELECT arr[1] FROM users")
    end

    it "builds lambda expressions" do
      hash = {
        type: :select,
        select: [{
          type: :function,
          name: "arrayMap",
          args: [
            { 
              type: :lambda, 
              args: [{ type: :column, name: "x" }], 
              body: { 
                type: :binary_op, 
                operator: "+", 
                left: { type: :column, name: "x" }, 
                right: { type: :number, value: "1" } 
              } 
            },
            { type: :column, name: "numbers" }
          ]
        }]
      }
      expect(described_class.new(hash).build).to eq("SELECT arrayMap(x -> x + 1, numbers)")
    end

    it "builds multi-argument lambda expressions" do
      hash = {
        type: :select,
        select: [{
          type: :function,
          name: "arrayMap",
          args: [
            { 
              type: :lambda, 
              args: [
                { type: :column, name: "x" }, 
                { type: :column, name: "y" }
              ], 
              body: { 
                type: :binary_op, 
                operator: "+", 
                left: { type: :column, name: "x" }, 
                right: { type: :column, name: "y" } 
              } 
            },
            { type: :column, name: "arr1" },
            { type: :column, name: "arr2" }
          ]
        }]
      }
      expect(described_class.new(hash).build).to eq("SELECT arrayMap((x, y) -> x + y, arr1, arr2)")
    end
  end
end
