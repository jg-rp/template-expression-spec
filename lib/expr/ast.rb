# frozen_string_literal: true

module Expr
  # Expression abstract syntax tree nodes.
  module AST
    Ternary = Data.define(:token, :expr, :condition, :else) do
      def evaluate(context)
        if Expr.truthy?(condition.evaluate(context))
          expr.evaluate(context)
        else
          self.else.evaluate(context)
        end
      end

      def children = [expr, condition, self.else]
      def to_s = "#{expr} if #{condition} else #{self.else}"
    end

    Filtered = Data.define(:token, :left, :filter) do
      def evaluate(context)
        filter_ = context.filters[filter.name]
        return :nothing if filter_.nil?

        lhs = left.evaluate(context)

        args = []
        kw_args = {}

        filter.args.each do |arg|
          if arg.is_a?(AST::KeywordArg)
            kw_args[arg.name] = arg.expr.evaluate(context)
          else
            args << arg.evaluate(context)
          end
        end

        if kw_args.empty?
          filter_.call(lhs, *args)
        else
          filter_.call(lhs, *args, **kw_args)
        end
      rescue ArgumentError, TypeError
        :nothing
      end

      def children = [left, filter]
      def to_s = "#{left} | #{filter}"
    end

    Coalesce = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = left.evaluate(context)
        lhs == :nothing ? right.evaluate(context) : lhs
      end

      def children = [left, right]
      def to_s = "#{left} ?? #{filter}"
    end

    Or = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = left.evaluate(context)
        Expr.truthy?(lhs) ? lhs : right.evaluate(context)
      end

      def children = [left, right]
      def to_s = "#{left} or #{right}"
    end

    And = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = left.evaluate(context)
        Expr.truthy?(lhs) ? right.evaluate(context) : lhs
      end

      def children = [left, right]
      def to_s = "#{left} and #{right}"
    end

    Not = Data.define(:token, :right) do
      def evaluate(context)
        !Expr.truthy?(right.evaluate(context))
      end

      def children = [right]
      def to_s = "not #{filter}"
    end

    Eq = Data.define(:token, :left, :right) do
      def evaluate(context) = Expr.eq?(left.evaluate(context), right.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} == #{right}"
    end

    Ne = Data.define(:token, :left, :right) do
      def evaluate(context) = !Expr.eq?(left.evaluate(context), right.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} != #{right}"
    end

    Lt = Data.define(:token, :left, :right) do
      def evaluate(context) = Expr.lt?(left.evaluate(context), right.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} < #{right}"
    end

    Le = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = left.evaluate(context)
        rhs = right.evaluate(context)
        Expr.lt?(lhs, rhs) || Expr.eq?(lhs, rhs)
      end

      def children = [left, right]
      def to_s = "#{left} <= #{right}"
    end

    Gt = Data.define(:token, :left, :right) do
      def evaluate(context) = Expr.lt?(right.evaluate(context), left.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} > #{right}"
    end

    Ge = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = left.evaluate(context)
        rhs = right.evaluate(context)
        Expr.lt?(rhs, lhs) || Expr.eq?(lhs, rhs)
      end

      def children = [left, right]
      def to_s = "#{left} >= #{right}"
    end

    Contains = Data.define(:token, :left, :right) do
      def evaluate(context) = Expr.contains?(left.evaluate(context), right.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} contains #{right}"
    end

    In = Data.define(:token, :left, :right) do
      def evaluate(context) = Expr.contains?(right.evaluate(context), left.evaluate(context))
      def children = [left, right]
      def to_s = "#{left} in #{right}"
    end

    Add = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = Expr.to_number(left.evaluate(context))
        rhs = Expr.to_number(right.evaluate(context))
        lhs == :nothing || rhs == :nothing ? :nothing : lhs + rhs
      end

      def children = [left, right]
      def to_s = "#{left} + #{right}"
    end

    Sub = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = Expr.to_number(left.evaluate(context))
        rhs = Expr.to_number(right.evaluate(context))
        lhs == :nothing || rhs == :nothing ? :nothing : lhs - rhs
      end

      def children = [left, right]
      def to_s = "#{left} - #{right}"
    end

    Mul = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = Expr.to_number(left.evaluate(context))
        rhs = Expr.to_number(right.evaluate(context))
        lhs == :nothing || rhs == :nothing ? :nothing : lhs * rhs
      end

      def children = [left, right]
      def to_s = "#{left} * #{right}"
    end

    Div = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = Expr.to_number(left.evaluate(context))
        rhs = Expr.to_number(right.evaluate(context))
        lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs / rhs
      end

      def children = [left, right]
      def to_s = "#{left} / #{right}"
    end

    Mod = Data.define(:token, :left, :right) do
      def evaluate(context)
        lhs = Expr.to_number(left.evaluate(context))
        rhs = Expr.to_number(right.evaluate(context))
        lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs % rhs
      end

      def children = [left, right]
      def to_s = "#{left} % #{right}"
    end

    Pos = Data.define(:token, :right) do
      def evaluate(context)
        Expr.to_number(right.evaluate(context))
      end

      def children = [right]
      def to_s = "+#{right}"
    end

    Neg = Data.define(:token, :right) do
      def evaluate(context)
        rhs = Expr.to_number(right.evaluate(context))
        rhs == :nothing ? rhs : -rhs
      end

      def children = [right]
      def to_s = "-#{right}"
    end

    Integer = Data.define(:token, :value) do
      def evaluate(context) = value
      def children = []
      def to_s = value.to_s
    end

    Float = Data.define(:token, :value) do
      def evaluate(context) = value
      def children = []
      def to_s = value.to_s
    end

    String = Data.define(:token, :segments) do
      def evaluate(context) = segments.map { |s| s.is_a?(::String) ? s : s.evaluate(context) }.join
      def children = segments.reject { |s| s.is_a?(::String) }
      def to_s = segments.map { |s| s.is_a?(::String) ? s : "${#{segment}}" }.join.inspect
    end

    Boolean = Data.define(:token, :value) do
      def evaluate(context) = value
      def children = []
      def to_s = value.to_s
    end

    Null = Data.define(:token) do
      def evaluate(context) = value
      def children = []
      def to_s = value.to_s
    end

    Array = Data.define(:token, :items) do
      def evaluate(context)
        items.map do |item|
          if item.is_a?(AST::Spread)
            Expr.to_array(item.expr.evaluate(context))
          else
            item.evaluate(context)
          end
        end
      end

      def children = items
      def to_s = "[#{items.map(&:to_s).join(", ")}]"
    end

    Object = Data.define(:token, :items) do
      def evaluate(context)
        result = {}
        items.each do |item|
          if item.is_a?(AST::Spread)
            result.merge!(Expr.to_object(item.expr.evaluate(context)))
          else
            result[item.key.evaluate(context)] = item.expr.evaluate(context)
          end
        end
        result
      end

      def children = items
      def to_s = "{#{items.map(&:to_s).join(", ")}}"
    end

    Spread = Data.define(:token, :expr) do
      def evaluate(context) = expr.evaluate(context)
      def children = [expr]
      def to_s = "...#{expr}"
    end

    Item = Data.define(:token, :key, :expr) do
      def evaluate(context) = expr.evaluate(context)
      def children = [key, expr]
      def to_s = "#{key}: #{expr}"
    end

    Range = Data.define(:token, :start, :stop) do
      def evaluate(context)
        a = Expr.to_number(start.evaluate(context))
        b = Expr.to_number(stop.evaluate(context))
        a == :nothing || b == :nothing ? [] : (a...b).to_a
      end

      def children = [start, stop]
      def to_s = "(#{start}..#{stop})"
    end

    Variable = Data.define(:token, :root, :segments) do
      def evaluate(context) = context.resolve(root, segments.map { |s| s.evaluate(context) })
      def children = segments.reject { |s| s.instance_of?(::String) || s.instance_of?(::Integer) }

      def to_s
        # TODO
        root
      end
    end

    Name = Data.define(:token, :value) do
      def evaluate(context) = value
      def children = []
      def to_s = value
    end

    Predicate = Data.define(:token, :value) do
      def evaluate(context) = value
      def children = []
      def to_s = value
    end

    Filter = Data.define(:token, :name, :args) do
      def evaluate(context) = :nothing
      def children = args

      def to_s
        if args && !args.empty?
          "#{name}: #{args.map(&:to_s).join(", ")}"
        else
          name
        end
      end
    end

    KeywordArg = Data.define(:token, :name, :expr) do
      def evaluate(context) = :nothing
      def children = [expr]
      def to_s = "#{name}=#{expr}"
    end

    Lambda = Data.define(:token, :params, :expr) do
      def evaluate(context)
        args = params.map(&:value)
        Expr::Lambda.new(args, expr, context)
      end

      def children = [expr]
      def to_s = "(#{params.map(&:to_s).join(",")}) => #{expr}"
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

        nodes << [prefix, connector, node.class.to_s, node.to_s]
        child_prefix = prefix + (is_last ? "    " : "│   ")
        node.children.each_with_index do |child, i|
          last = i == node.children.length - 1
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
