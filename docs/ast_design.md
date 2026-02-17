# ClickHouse Query AST Design

This document describes the Hash structure that represents parsed ClickHouse SQL queries.

## Common Types
- **Column**: `{ type: :column, name: "column_name", table: "table_alias" (optional) }`
- **Literal**: `{ type: :literal, value: "some_value" (string, number, boolean) }`
- **Function**: `{ type: :function, name: "count", args: [...] }`
- **Star**: `{ type: :star }`

## SELECT Query
```ruby
{
  type: :select,
  select: [
    { type: :column, name: "id" },
    { type: :function, name: "count", args: [{ type: :star }] }
  ],
  from: { type: :table, name: "users", alias: "u" },
  # optional
  where: {
    type: :binary_op,
    operator: "=",
    left: { type: :column, name: "age" },
    right: { type: :literal, value: 18 }
  },
  group_by: [
    { type: :column, name: "department_id" }
  ],
  order_by: [
    { expr: { type: :column, name: "created_at" }, direction: :desc }
  ],
  limit: { type: :literal, value: 10 }
}
```

## Operators
Binary operators are represented as:
```ruby
{
  type: :binary_op,
  operator: "AND",
  left: { ... },
  right: { ... }
}
```

## INSERT Query
```ruby
{
  type: :insert,
  table: { type: :table, name: "users" },
  columns: ["id", "name"],
  values: [
    [1, "Alice"],
    [2, "Bob"]
  ],
  # OR
  format: "JSONEachRow"
}
```

## CREATE TABLE
```ruby
{
  type: :create_table,
  name: "events",
  columns: [
    { name: "id", type: "UInt64" },
    { name: "timestamp", type: "DateTime" }
  ],
  engine: "MergeTree",
  order_by: ["id", "timestamp"]
}
```
