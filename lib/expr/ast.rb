# frozen_string_literal: true

module Expr
  module AST
    Ternary = Data.define(:token, :expr, :condition, :else)
    Filtered = Data.define(:token, :left, :filter)

    Coalesce = Data.define(:token, :left, :right)
    Or = Data.define(:token, :left, :right)
    And = Data.define(:token, :left, :right)
    Not = Data.define(:token, :right)

    Eq = Data.define(:token, :left, :right)
    Ne = Data.define(:token, :left, :right)
    Lt = Data.define(:token, :left, :right)
    Le = Data.define(:token, :left, :right)
    Gt = Data.define(:token, :left, :right)
    Ge = Data.define(:token, :left, :right)

    Contains = Data.define(:token, :left, :right)
    In = Data.define(:token, :left, :right)

    Add = Data.define(:token, :left, :right)
    Sub = Data.define(:token, :left, :right)
    Mul = Data.define(:token, :left, :right)
    Div = Data.define(:token, :left, :right)
    Mod = Data.define(:token, :left, :right)

    Pos = Data.define(:token, :right)
    Neg = Data.define(:token, :right)

    Integer = Data.define(:token, :value)
    Float = Data.define(:token, :value)
    String = Data.define(:token, :segments)
    Boolean = Data.define(:token, :value)
    Null = Data.define(:token)

    Array = Data.define(:token, :items)
    Object = Data.define(:token, :items)
    Spread = Data.define(:token, :expr)
    Item = Data.define(:token, :key, :expr)

    Range = Data.define(:token, :start, :stop)
    Variable = Data.define(:token, :root, :segments)
    Name = Data.define(:token, :value)

    Filter = Data.define(:token, :name, :args)
    KeywordArg = Data.define(:token, :name, :expr)
    Lambda = Data.define(:token, :params, :expr)

    def self.children(e)
      case e
      when KeywordArg, Lambda, Spread
        [e.expr]
      when Ternary
        if e.condition
          [e.expr, e.condition, e.else]
        else
          [e.expr]
        end
      when Filtered
        [e.left, e.filter]
      when Filter
        e.args
      when Coalesce, And, Or, Eq, Ne, Lt, Le, Gt, Ge, Contains, In, Add, Sub, Mul, Div, Mod
        [e.left, e.right]
      when Not, Pos, Neg
        [e.right]
      when Integer, Float, Boolean, Null, Name
        []
      when String
        e.segments.reject { |s| s.is_a?(::String) }
      when Array, Object
        e.items
      when Item
        [e.key, e.expr]
      when Range
        [e.start, e.stop]
      when Variable
        if e.segments
          e.segments.reject { |s| s.instance_of?(::String) || s.instance_of?(::Integer) }
        else
          []
        end
      else
        raise "unknown expression #{e.class}"
      end
    end

    def self.to_s(e)
      case e
      when Ternary
        if e.condition
          "#{to_s(e.expr)} if #{to_s(e.condition)} else #{to_s(e.else)}"
        else
          to_s(e.expr)
        end
      when Filtered
        "#{to_s(e.left)} | #{to_s(e.filter)}"
      when Filter
        if e.args && !e.args.empty?
          args = e.args.map { |arg| to_s(arg) }
          "#{e.name}: #{args.join(", ")}"
        else
          e.name
        end
      when KeywordArg
        "#{e.name}=#{to_s(e.expr)}"
      when Coalesce
        "#{to_s(e.left)} ?? #{to_s(e.right)}"
      when And
        "#{to_s(e.left)} and #{to_s(e.right)}"
      when Or
        "#{to_s(e.left)} or #{to_s(e.right)}"
      when Not
        "not #{to_s(e.right)}"
      when Eq
        "#{to_s(e.left)} == #{to_s(e.right)}"
      when Ne
        "#{to_s(e.left)} != #{to_s(e.right)}"
      when Lt
        "#{to_s(e.left)} < #{to_s(e.right)}"
      when Le
        "#{to_s(e.left)} <= #{to_s(e.right)}"
      when Gt
        "#{to_s(e.left)} > #{to_s(e.right)}"
      when Ge
        "#{to_s(e.left)} >= #{to_s(e.right)}"
      when Contains
        "#{to_s(e.left)} contains #{to_s(e.right)}"
      when In
        "#{to_s(e.left)} in #{to_s(e.right)}"
      when Add
        "#{to_s(e.left)} + #{to_s(e.right)}"
      when Sub
        "#{to_s(e.left)} - #{to_s(e.right)}"
      when Mul
        "#{to_s(e.left)} * #{to_s(e.right)}"
      when Div
        "#{to_s(e.left)} / #{to_s(e.right)}"
      when Mod
        "#{to_s(e.left)} % #{to_s(e.right)}"
      when Pos
        "+#{to_s(e.right)}"
      when Neg
        "-#{to_s(e.right)}"
      when Integer, Float, Boolean
        e.value.to_s
      when String
        e.segments.map do |segment|
          segment.is_a?(::String) ? segment : "${#{to_s(segment)}}"
        end.join.inspect
      when Null
        "null"
      when Name
        e.value
      when Array
        items = e.items.map { |item| to_s(item) }
        "[#{items.join(", ")}]"
      when Object
        items = e.items.map { |item| to_s(item) }
        "{#{items.join(", ")}}"
      when Item
        "#{to_s(e.key)}: #{to_s(e.expr)}"
      when Spread
        "...#{to_s(e.expr)}"
      when Range
        "(#{to_s(e.start)}..#{to_s(e.stop)})"
      when Variable
        # TODO:
        e.root
      when Lambda
        params = e.params.map { |p| to_s(p) }.join(",")
        "(#{params}) => #{to_s(e.expr)}"
      else
        raise "unknown expression #{e.class}"
      end
    end

    def self.tree_view(e)
      # (prefix, connector, class_name, inspect_value)
      nodes = [] # : Array[[String, String, String, String]]

      # @type var visit: ^(Expression, String, bool) -> void
      visit = lambda do |node, prefix, is_last|
        connector = if prefix.empty?
                      ""
                    elsif is_last
                      "└── "
                    else
                      "├── "
                    end

        nodes << [prefix, connector, node.class.to_s, to_s(node)]
        child_prefix = prefix + (is_last ? "    " : "│   ")
        children(node).each_with_index do |child, i|
          last = i == children(node).length - 1
          visit.call(child, child_prefix, last)
        end
      end

      visit.call(e, "", true)

      widths = nodes.map { |prefix, connector, cls| (prefix + connector + cls).length }
      max_width = widths.max || 0

      lines = [] # : Array[String]
      nodes.zip(widths).each do |node, width|
        prefix, connector, cls, val = node
        left = prefix + connector + cls
        padding = " " * (max_width - (width || raise) + 4)
        lines << (left + padding + val)
      end

      lines.join("\n")
    end
  end
end
