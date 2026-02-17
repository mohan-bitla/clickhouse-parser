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
    
    it "SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 18 and users.age > 30 UNION ALL SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 50 and users.age < 60 ORDER BY users.age UNION ALL SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 70 and users.age < 80 ORDER BY users.age LIMIT 100" do
      sql = "SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 18 and users.age > 30 UNION ALL SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 50 and users.age < 60 ORDER BY users.age UNION ALL SELECT users.name, users.age, profile.dob FROM users left join profiles on users.id = profiles.user_id where users.age > 70 and users.age < 80 ORDER BY users.age LIMIT 100"
      result = parse(sql)
      
      builder = ClickhouseQueryParser::Builder.new(result)
      expected_sql = sql.gsub("where", "WHERE")
                        .gsub("left join", "LEFT JOIN")
                        .gsub("on", "ON")
                        .gsub("and", "AND")
                        .gsub("ORDER BY users.age", "ORDER BY users.age ASC")
      
      expect(builder.build).to eq(expected_sql)
      
      # Basic structure check (first level should be a UNION ALL)
      expect(result[:type]).to eq(:union_all)
      
      # Drill down could be verbose, but the builder success gives good confidence.
      # Let's check the structure of the left-most part
      
      # The structure is (Query1 UNION ALL Query2) UNION ALL Query3
      # wait, parser does loop: left = { union: left, right: right }
      # So 1, 2, 3 -> (1 U 2) U 3
      
      expect(result[:right][:type]).to eq(:select) # Query 3
      expect(result[:left][:type]).to eq(:union_all) # Query 1 U 2
      expect(result[:left][:left][:type]).to eq(:select) # Query 1
      expect(result[:left][:right][:type]).to eq(:select) # Query 2

      # Check WHERE clause for logic op
      query1 = result[:left][:left]
      expect(query1[:where][:type]).to eq(:binary_op)
      expect(query1[:where][:operator]).to eq("AND")
    end

  end
end