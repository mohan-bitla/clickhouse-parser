# frozen_string_literal: true

module ClickhouseQueryParser
  class Parser
    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    def parse
      token = current_token
      return nil unless token

      if match?(:keyword, "SELECT")
        left = parse_select
        
        while match?(:keyword, "UNION")
          consume(:keyword, "UNION")
          consume(:keyword, "ALL")
          right = parse_select
          left = { type: :union_all, left: left, right: right }
        end
        
        left
      else
        raise Error, "Unexpected token: #{token.inspect}"
      end
    end

    private

    def current_token
      @tokens[@pos]
    end

    def advance
      @pos += 1
      current_token
    end

    def consume(type, value = nil)
      token = current_token
      if token && token[:type] == type && (value.nil? || token[:value] == value)
        advance
        token
      else
        raise Error, "Expected #{type} #{value}, got #{token.inspect}"
      end
    end

    def match?(type, value = nil)
      token = current_token
      token && token[:type] == type && (value.nil? || token[:value] == value)
    end

    def parse_select
      consume(:keyword, "SELECT")
      columns = parse_select_list
      
      from = nil
      if match?(:keyword, "FROM")
        consume(:keyword, "FROM")
        from = parse_table
      end

      result = { type: :select, select: columns }
      result[:from] = from if from

      if match?(:keyword, "LEFT") || match?(:keyword, "RIGHT") || match?(:keyword, "INNER") || match?(:keyword, "OUTER") || match?(:keyword, "JOIN")
        result[:join] = parse_join
      end

      if match?(:keyword, "WHERE")
        consume(:keyword, "WHERE")
        result[:where] = parse_logic_or
      end

      if match?(:keyword, "GROUP")
        consume(:keyword, "GROUP")
        consume(:keyword, "BY")
        result[:group_by] = parse_select_list
      end

      if match?(:keyword, "ORDER")
        consume(:keyword, "ORDER")
        consume(:keyword, "BY")
        result[:order_by] = parse_order_by_list
      end

      if match?(:keyword, "LIMIT")
        consume(:keyword, "LIMIT")
        result[:limit] = parse_literal
      end

      result
    end


    def parse_select_list
      columns = []
      loop do
        columns << parse_logic_or
        break unless match?(:comma)
        consume(:comma)
      end
      columns
    end

    def parse_order_by_list
      list = []
      loop do
        expr = parse_logic_or
        direction = :asc
        if match?(:keyword, "DESC")
          consume(:keyword, "DESC")
          direction = :desc
        elsif match?(:keyword, "ASC")
          consume(:keyword, "ASC")
        end
        list << { expr: expr, direction: direction }
        break unless match?(:comma)
        consume(:comma)
      end
      list
    end

    def parse_logic_or
      left = parse_logic_and
      
      while match?(:keyword, "OR")
        op = consume(:keyword, "OR")
        right = parse_logic_and
        left = { type: :binary_op, operator: "OR", left: left, right: right }
      end
      
      left
    end

    def parse_logic_and
      left = parse_expression
      
      while match?(:keyword, "AND")
        op = consume(:keyword, "AND")
        right = parse_expression
        left = { type: :binary_op, operator: "AND", left: left, right: right }
      end
      
      left
    end

    def parse_expression
      left = parse_primary
      
      if match?(:operator)
        op = consume(:operator)
        right = parse_primary
        { type: :binary_op, operator: op[:value], left: left, right: right }
      else
        left
      end
    end

    def parse_primary
      token = current_token
      case token[:type]
      when :identifier
        name = token[:value]
        consume(:identifier)
        if match?(:dot)
          consume(:dot)
          column_token = consume(:identifier)
          { type: :column, name: column_token[:value], table: name }
        elsif match?(:lparen)
          parse_function_call(name)
        else
          { type: :column, name: name }
        end
      when :keyword
        if token[:value] == "INTERVAL"
           parse_interval
        elsif token[:value] == "EXTRACT"
           parse_extract
        else
           # In our tokenizer, standard functions are just identifiers unless explicitly in keywords list.
           # But if we want to be safe, we can handle it. For now, assume functions are identifiers.
           raise Error, "Unexpected keyword in expression: #{token[:value]}"
        end
      when :star
        consume(:star)
        { type: :star }
      when :number
        consume(:number)
        { type: :number, value: token[:value] }
      when :string
        consume(:string)
        { type: :string, value: token[:value] }
      else
        raise Error, "Unexpected token in expression: #{token.inspect}"
      end
    end

    def parse_function_call(name)
      consume(:lparen)
      args = []
      unless match?(:rparen)
        loop do
          args << parse_logic_or
          break unless match?(:comma)
          consume(:comma)
        end
      end
      consume(:rparen)
      { type: :function, name: name, args: args }
    end

    def parse_join
      type = :join
      if match?(:keyword, "LEFT")
        consume(:keyword, "LEFT")
        consume(:keyword, "JOIN")
        type = :left_join
      elsif match?(:keyword, "RIGHT")
        consume(:keyword, "RIGHT")
        consume(:keyword, "JOIN")
        type = :right_join
      elsif match?(:keyword, "INNER")
        consume(:keyword, "INNER")
        consume(:keyword, "JOIN")
        type = :inner_join
      else
        consume(:keyword, "JOIN")
      end

      table = parse_table
      
      on = nil
      if match?(:keyword, "ON")
        consume(:keyword, "ON")
        on = parse_logic_or
      end
      
      { type: type, table: table, on: on }
    end

    def parse_table
      token = consume(:identifier)
      { type: :table, name: token[:value] }
    end
    
    def parse_literal
       token = current_token
       if token[:type] == :number
         consume(:number)
         { type: :number, value: token[:value] }
       elsif token[:type] == :string
         consume(:string)
         { type: :string, value: token[:value] }
       else
          raise Error, "Expected literal, got #{token.inspect}"
       end
    end

    def parse_interval
      consume(:keyword, "INTERVAL")
      value_token = current_token
      value = if value_token[:type] == :string
                consume(:string)[:value]
              elsif value_token[:type] == :number
                consume(:number)[:value]
              else
                 raise Error, "Expected interval value, got #{value_token.inspect}"
              end
      
      if match?(:keyword)
         unit = consume(:keyword)[:value]
         { type: :interval, value: value, unit: unit }
      else
         raise Error, "Expected interval unit, got #{current_token.inspect}"
      end
    end

    def parse_extract
      consume(:keyword, "EXTRACT")
      consume(:lparen)
      
      unit = if match?(:keyword)
               consume(:keyword)[:value]
             elsif match?(:identifier)
               consume(:identifier)[:value]
             else
               raise Error, "Expected EXTRACT unit, got #{current_token.inspect}"
             end

      consume(:keyword, "FROM")
      expr = parse_expression
      consume(:rparen)
      
      { type: :function, name: "EXTRACT", args: [{ type: :interval_unit, value: unit }, expr] }
    end
  end
end
