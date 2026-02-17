# frozen_string_literal: true

module ClickhouseQueryParser
  class Builder
    def initialize(hash)
      @hash = hash
    end

    def build
      case @hash[:type]
      when :select
        build_select
      when :union_all
        "#{Builder.new(@hash[:left]).build} UNION ALL #{Builder.new(@hash[:right]).build}"
      else
        raise Error, "Unknown query type: #{@hash[:type]}"
      end
    end

    private

    def build_select
      parts = ["SELECT"]
      parts << @hash[:select].map { |col| build_expression(col) }.join(", ")
      
      if @hash[:from]
        parts << "FROM"
        parts << build_table(@hash[:from])
      end

      if @hash[:join]
        join_type = case @hash[:join][:type]
                    when :left_join then "LEFT JOIN"
                    when :right_join then "RIGHT JOIN"
                    when :inner_join then "INNER JOIN"
                    else "JOIN"
                    end
        parts << join_type
        parts << build_table(@hash[:join][:table])
        if @hash[:join][:on]
          parts << "ON"
          parts << build_expression(@hash[:join][:on])
        end
      end

      if @hash[:where]
        parts << "WHERE"
        parts << build_expression(@hash[:where])
      end

      if @hash[:group_by]
        parts << "GROUP BY"
        parts << @hash[:group_by].map { |expr| build_expression(expr) }.join(", ")
      end

      if @hash[:order_by]
        parts << "ORDER BY"
        parts << @hash[:order_by].map do |item|
          "#{build_expression(item[:expr])} #{item[:direction].to_s.upcase}"
        end.join(", ")
      end

      if @hash[:limit]
        parts << "LIMIT"
        parts << build_expression(@hash[:limit])
      end

      parts.join(" ")
    end

    def build_expression(expr)
      case expr[:type]
      when :column
        if expr[:table]
          "#{expr[:table]}.#{expr[:name]}"
        else
          expr[:name]
        end
      when :star
        "*"
      when :number
        expr[:value].to_s
      when :string
        "'#{expr[:value]}'"
      when :table
        expr[:name]
      when :binary_op
        "#{build_expression(expr[:left])} #{expr[:operator]} #{build_expression(expr[:right])}"
      when :function
        args = expr[:args].map { |a| build_expression(a) }.join(", ")
        "#{expr[:name]}(#{args})"
      else
        raise Error, "Unknown expression type: #{expr[:type]}"
      end
    end

    def build_table(table)
      table[:name]
    end
  end
end
