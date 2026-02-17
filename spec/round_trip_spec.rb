# frozen_string_literal: true

require "spec_helper"
require "clickhouse_query_parser"

RSpec.describe "Round Trip" do
  it "parses and builds a complex query back to original SQL" do
    sql = "SELECT id, count(*) FROM users WHERE age > 18 GROUP BY id ORDER BY id DESC LIMIT 5"
    parsed = ClickhouseQueryParser.parse(sql)
    built = ClickhouseQueryParser.build(parsed)
    
    # The builder puts space around parts, so it should match exactly if we implemented it right.
    # Our builder outputs: SELECT ... FROM ... WHERE ... GROUP BY ... ORDER BY ... LIMIT ...
    # Our tokenizer / parser preserves structure but not whitespace, the builder enforces standard spacing.
    # The input SQL I drafted above uses standard spacing so it should match.
    
    expect(built).to eq(sql)
  end
end
