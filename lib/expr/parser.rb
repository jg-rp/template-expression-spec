# frozen_string_literal: true

require "pestle"
require_relative "ast"
require_relative "unescape"

module Expr
  class Parser < Pestle::PrattParser
    PREFIX_OPS = {
      not: 6,
      neg: 10,
      pos: 10
    }.freeze

    INFIX_OPS = {
      pipe: [2, LEFT_ASSOC],
      coalesce: [3, LEFT_ASSOC],
      or: [4, LEFT_ASSOC],
      and: [5, LEFT_ASSOC],
      eq: [7, LEFT_ASSOC],
      ne: [7, LEFT_ASSOC],
      lt: [7, LEFT_ASSOC],
      le: [7, LEFT_ASSOC],
      gt: [7, LEFT_ASSOC],
      ge: [7, LEFT_ASSOC],
      contains: [7, LEFT_ASSOC],
      in: [7, LEFT_ASSOC],
      add: [8, LEFT_ASSOC],
      sub: [8, LEFT_ASSOC],
      mul: [9, LEFT_ASSOC],
      div: [9, LEFT_ASSOC],
      mod: [9, LEFT_ASSOC]
    }.freeze

    POSTFIX_OPS = {}.freeze

    def initialize(parser)
      super()
      @parser = parser
    end

    def parse(expression)
      pairs = @parser.parse(:expression, expression)
      parse_expr(pairs.first.stream)
    end

    def parse_primary(pair)
      case pair
      in :number, _
        parse_number(pair)
      in :double_quoted | :single_quoted, _
        parse_string(pair)
      in :true_literal, _
        AST::Boolean.new(pair, true)
      in :false_literal, _
        AST::Boolean.new(pair, false)
      in :null_literal, _
        AST::Null.new(pair)
      in :array_literal, _
        parse_array(pair)
      in :object_literal, _
        parse_object(pair)
      in :range_literal, _
        parse_range(pair)
      in :variable, _
        parse_variable(pair)
      else
        raise "unexpected #{pair.rule} #{pair.text.inspect}"
      end
    end

    def parse_prefix(op, rhs)
      case op
      in :not
        AST::Not.new(op, rhs)
      in :neg
        AST::Neg.new(op, rhs)
      in :pos
        AST::Pos.new(op, rhs)
      else
        raise "unexpected prefix operator #{op.text.inspect}"
      end
    end

    def parse_postfix(lhs, op) # rubocop: disable Lint/UnusedMethodArgument
      raise "unknown postfix operator #{op.text.inspect}"
    end

    def parse_infix(lhs, op, rhs)
      case op
      in :pipe, _
        AST::Filtered.new(op, lhs, rhs)
      in :coalesce, _
        AST::Coalesce.new(op, lhs, rhs)
      in :or, _
        AST::Or.new(op, lhs, rhs)
      in :and, _
        AST::And.new(op, lhs, rhs)
      in :eq, _
        AST::Eq.new(op, lhs, rhs)
      in :ne, _
        AST::Ne.new(op, lhs, rhs)
      in :lt, _
        AST::Lt.new(op, lhs, rhs)
      in :le, _
        AST::Le.new(op, lhs, rhs)
      in :gt, _
        AST::Gt.new(op, lhs, rhs)
      in :ge, _
        AST::Ge.new(op, lhs, rhs)
      in :contains, _
        AST::Contains.new(op, lhs, rhs)
      in :in, _
        AST::In.new(op, lhs, rhs)
      in :add, _
        AST::Add.new(op, lhs, rhs)
      in :sub, _
        AST::Sub.new(op, lhs, rhs)
      in :mul, _
        AST::Mul.new(op, lhs, rhs)
      in :div, _
        AST::Div.new(op, lhs, rhs)
      in :mod, _
        AST::Mod.new(op, lhs, rhs)
      else
        raise "unknown infix operator #{op.text.inspect}"
      end
    end

    def parse_number(pair)
      case pair
      in :number, [int]
        AST::Integer.new(pair, int.text.to_i)
      in :number, [int, [:frac, _], *]
        AST::Float.new(pair, pair.text.to_f)
      in :number, [int, [:expr, _]]
        text = pair.text
        if text.include?("-")
          # negative exponent
          AST::Float.new(text.to_f)
        else
          AST::Integer.new(text.to_f.to_i)
        end
      else
        raise "expected :number, found #{pair.rule.inspect}"
      end
    end

    def parse_string(pair)
      segments = pair.map { |child| parse_string_segment(child) }
      AST::String.new(pair, segments)
    end

    def parse_string_segment(pair)
      case pair
      in :unescaped_segment, _
        pair.text
      in :double_quoted_escaped | :single_quoted_escaped, _
        Expr.unescape(pair)
      in :expr, _
        parse_expr(pair.stream)
      else
        raise "unexpected string segment #{pair.rule.inspect} #{pair.text.inspect}"
      end
    end

    def parse_variable(pair)
      # TODO:
      raise "not implemented"
    end
  end
end
