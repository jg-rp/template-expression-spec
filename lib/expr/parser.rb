# frozen_string_literal: true

require_relative "ast"

module Expr
  class Parser < Pestle::PrattParser
    PREFIX_OPS = {
      not_expr: 6,
      neg_expr: 10,
      pos_expr: 10
    }.freeze

    INFIX_OPS = {
      condition: [1, LEFT_ASSOC],
      filter: [2, LEFT_ASSOC],
      coalesce_expr: [3, LEFT_ASSOC],
      or_expr: [4, LEFT_ASSOC],
      and_expr: [5, LEFT_ASSOC],
      test_expr: [7, LEFT_ASSOC],
      add_expr: [8, LEFT_ASSOC],
      sub_expr: [8, LEFT_ASSOC],
      mul_expr: [9, LEFT_ASSOC],
      div_expr: [9, LEFT_ASSOC],
      mod_expr: [9, LEFT_ASSOC]
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
        raise "unexpected #{pair.text.inspect}"
      end
    end

    def parse_prefix(op, rhs)
      case op
      in :not_expr
        AST::Not.new(op, rhs)
      in :neg_expr
        AST::Neg.new(op, rhs)
      in :pos_expr
        AST::Pos.new(op, rhs)
      else
        raise "unexpected prefix operator #{op.text.inspect}"
      end
    end

    def parse_postfix(lhs, op)
      raise "unknown postfix operator #{op.text.inspect}"
    end

    def parse_infix(lhs, op, rhs)
      # TODO:
    end
  end
end
