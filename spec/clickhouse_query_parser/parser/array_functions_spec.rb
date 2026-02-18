# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser"

RSpec.describe ClickhouseQueryParser::Parser do
  def parse(sql)
    tokens = ClickhouseQueryParser::Tokenizer.new(sql).tokenize
    described_class.new(tokens).parse
  end

  describe "Array Functions" do
    it "parses array literals" do
      sql = "SELECT [1, 2, 3] FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :array,
        values: [
          { type: :number, value: "1" },
          { type: :number, value: "2" },
          { type: :number, value: "3" }
        ]
      })
    end

    it "parses arrayMap with lambda" do
      sql = "SELECT arrayMap(x -> x + 1, numbers) FROM system.numbers"
      result = parse(sql)
      
      # lambda should be parsed as an expression or special type
      expect(result[:select][0]).to eq({
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
      })
    end

    it "parses arrayFilter with lambda" do
      sql = "SELECT arrayFilter(x -> x > 10, numbers) FROM system.numbers"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :function,
        name: "arrayFilter",
        args: [
          { 
            type: :lambda, 
            args: [{ type: :column, name: "x" }], 
            body: { 
              type: :binary_op, 
              operator: ">", 
              left: { type: :column, name: "x" }, 
              right: { type: :number, value: "10" } 
            } 
          },
          { type: :column, name: "numbers" }
        ]
      })
    end
    
    it "parses array element access" do
      sql = "SELECT arr[1] FROM users"
      result = parse(sql)
      expect(result[:select][0]).to eq({
        type: :array_access,
        column: { type: :column, name: "arr" },
        index: { type: :number, value: "1" }
      })
    end

    it "parses multi-argument lambda" do
      sql = "SELECT arrayMap((x, y) -> x + y, arr1, arr2)"
      result = parse(sql)
      expect(result[:select][0]).to eq({
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
      })
    end

    it "parses various array functions" do
      functions = [
        "arrayUniq(arr)",
        "arrayPushBack(arr, 1)",
        "arrayPopFront(arr)",
        "length(arr)",
        "empty(arr)"
      ]
      
      functions.each do |func|
        sql = "SELECT #{func}"
        result = parse(sql)
        expect(result[:select][0][:type]).to eq(:function)
      end
    end
  end
end
