# frozen_string_literal: true

require "pestle"
require_relative "ast"

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
      parse_expr(pairs.first.inner.first.stream)
    end

    def parse_primary(pair)
      case pair
      in :number, _
        parse_number(pair)
      in :string_literal, _
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
        AST::Filtered.new(lhs, rhs)
      in :coalesce, _
        AST::Coalesce.new(lhs, rhs)
      in :or, _
        AST::Or.new(lhs, rhs)
      in :and, _
        AST::And.new(lhs, rhs)
      in :eq, _
        AST::Eq.new(lhs, rhs)
      in :ne, _
        AST::Ne.new(lhs, rhs)
      in :lt, _
        AST::Lt.new(lhs, rhs)
      in :le, _
        AST::Le.new(lhs, rhs)
      in :gt, _
        AST::Gt.new(lhs, rhs)
      in :ge, _
        AST::Ge.new(lhs, rhs)
      in :contains, _
        AST::Contains.new(lhs, rhs)
      in :in, _
        AST::In.new(lhs, rhs)
      in :add, _
        AST::Add.new(lhs, rhs)
      in :sub, _
        AST::Sub.new(lhs, rhs)
      in :mul, _
        AST::Mul.new(lhs, rhs)
      in :div, _
        AST::Div.new(lhs, rhs)
      in :mod, _
        AST::Mod.new(lhs, rhs)
      else
        raise "unknown infix operator #{op.text.inspect}"
      end
    end
  end
end
