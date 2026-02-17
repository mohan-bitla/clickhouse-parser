require "spec_helper"
require "clickhouse_query_parser/builder"

RSpec.describe ClickhouseQueryParser::Builder do
  describe "#build" do
    it "builds with UNION ALL" do
      hash = {type: :union_all,
        left:
          {type: :union_all,
          left:
            {type: :select,
            select:
              [{type: :column, name: "name", table: "users"},
              {type: :column, name: "age", table: "users"},
              {type: :column, name: "dob", table: "profile"}],
            from: {type: :table, name: "users"},
            join:
              {type: :left_join,
              table: {type: :table, name: "profiles"},
              on:
                {type: :binary_op,
                operator: "=",
                left: {type: :column, name: "id", table: "users"},
                right: {type: :column, name: "user_id", table: "profiles"}}},
            where:
              {type: :binary_op,
              operator: "AND",
              left:
                {type: :binary_op,
                operator: ">",
                left: {type: :column, name: "age", table: "users"},
                right: {type: :number, value: "18"}},
              right:
                {type: :binary_op,
                operator: ">",
                left: {type: :column, name: "age", table: "users"},
                right: {type: :number, value: "30"}}}},
          right:
            {type: :select,
            select:
              [{type: :column, name: "name", table: "users"},
              {type: :column, name: "age", table: "users"},
              {type: :column, name: "dob", table: "profile"}],
            from: {type: :table, name: "users"},
            join:
              {type: :left_join,
              table: {type: :table, name: "profiles"},
              on:
                {type: :binary_op,
                operator: "=",
                left: {type: :column, name: "id", table: "users"},
                right: {type: :column, name: "user_id", table: "profiles"}}},
            where:
              {type: :binary_op,
              operator: "AND",
              left:
                {type: :binary_op,
                operator: ">",
                left: {type: :column, name: "age", table: "users"},
                right: {type: :number, value: "50"}},
              right:
                {type: :binary_op,
                operator: "<",
                left: {type: :column, name: "age", table: "users"},
                right: {type: :number, value: "60"}}},
            order_by: [{expr: {type: :column, name: "age", table: "users"}, direction: :asc}]}},
        right:
          {type: :select,
          select:
            [{type: :column, name: "name", table: "users"},
            {type: :column, name: "age", table: "users"},
            {type: :column, name: "dob", table: "profile"}],
          from: {type: :table, name: "users"},
          join:
            {type: :left_join,
            table: {type: :table, name: "profiles"},
            on:
              {type: :binary_op,
              operator: "=",
              left: {type: :column, name: "id", table: "users"},
              right: {type: :column, name: "user_id", table: "profiles"}}},
          where:
            {type: :binary_op,
            operator: "AND",
            left:
              {type: :binary_op,
              operator: ">",
              left: {type: :column, name: "age", table: "users"},
              right: {type: :number, value: "70"}},
            right:
              {type: :binary_op,
              operator: "<",
              left: {type: :column, name: "age", table: "users"},
              right: {type: :number, value: "80"}}},
          order_by: [{expr: {type: :column, name: "age", table: "users"}, direction: :asc}],
          limit: {type: :number, value: "100"}}} 
      
      expect(described_class.new(hash).build).to eq("SELECT users.name, users.age, profile.dob FROM users LEFT JOIN profiles ON users.id = profiles.user_id WHERE users.age > 18 AND users.age > 30 UNION ALL SELECT users.name, users.age, profile.dob FROM users LEFT JOIN profiles ON users.id = profiles.user_id WHERE users.age > 50 AND users.age < 60 ORDER BY users.age ASC UNION ALL SELECT users.name, users.age, profile.dob FROM users LEFT JOIN profiles ON users.id = profiles.user_id WHERE users.age > 70 AND users.age < 80 ORDER BY users.age ASC LIMIT 100")
    end
  end
end