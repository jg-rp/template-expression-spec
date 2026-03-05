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
      case pair.rule
      when :expr, :arg_expr
        parse_expr(pair.stream)
      when :ternary_expr, :arg_ternary_expr
        parse_ternary(pair)
      when :filter_invocation
        parse_filter(pair)
      when :keyword_argument
        parse_keyword_arg(pair)
      when :lambda_expr
        parse_lambda(pair)
      when :variable
        parse_variable(pair)
      when :range_literal
        parse_range(pair)
      when :array_literal
        parse_array(pair)
      when :object_literal
        parse_object(pair)
      when :number
        parse_number(pair)
      when :double_quoted, :single_quoted, :double_quoted_name, :single_quoted_name
        parse_string(pair)
      when :true_literal
        AST::Boolean.new(pair, true)
      when :false_literal
        AST::Boolean.new(pair, false)
      when :null_literal
        AST::Null.new(pair)
      else
        raise "unexpected #{pair.rule.inspect} #{pair.text.inspect}"
      end
    end

    def parse_prefix(op, rhs)
      case op.rule
      when :not
        AST::Not.new(op, rhs)
      when :neg
        AST::Neg.new(op, rhs)
      when :pos
        AST::Pos.new(op, rhs)
      else
        raise "unexpected prefix operator #{op.rule.inspect} #{op.text.inspect}"
      end
    end

    def parse_infix(lhs, op, rhs)
      case op.rule
      when :pipe
        AST::Filtered.new(op, lhs, rhs)
      when :coalesce
        AST::Coalesce.new(op, lhs, rhs)
      when :or
        AST::Or.new(op, lhs, rhs)
      when :and
        AST::And.new(op, lhs, rhs)
      when :eq
        AST::Eq.new(op, lhs, rhs)
      when :ne
        AST::Ne.new(op, lhs, rhs)
      when :lt
        AST::Lt.new(op, lhs, rhs)
      when :le
        AST::Le.new(op, lhs, rhs)
      when :gt
        AST::Gt.new(op, lhs, rhs)
      when :ge
        AST::Ge.new(op, lhs, rhs)
      when :contains
        AST::Contains.new(op, lhs, rhs)
      when :in
        AST::In.new(op, lhs, rhs)
      when :add
        AST::Add.new(op, lhs, rhs)
      when :sub
        AST::Sub.new(op, lhs, rhs)
      when :mul
        AST::Mul.new(op, lhs, rhs)
      when :div
        AST::Div.new(op, lhs, rhs)
      when :mod
        AST::Mod.new(op, lhs, rhs)
      else
        raise "unknown infix operator #{op.text.inspect}"
      end
    end

    def parse_postfix(lhs, op) # rubocop: disable Lint/UnusedMethodArgument
      raise "unknown postfix operator #{op.text.inspect}"
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
      AST::String.new(pair, pair.map { |child| parse_string_segment(child) })
    end

    def parse_string_segment(pair)
      case pair.rule
      when :unescaped_segment
        pair.text
      when :double_quoted_escaped, :single_quoted_escaped
        Expr.unescape(pair)
      when :expr
        parse_expr(pair.stream)
      else
        raise "unexpected string segment #{pair.rule.inspect} #{pair.text.inspect}"
      end
    end

    def parse_array(pair)
      AST::Array.new(pair, pair.map { |item| parse_array_item(item) })
    end

    def parse_array_item(pair)
      case pair.rule
      when :expr
        parse_expr(pair.stream)
      when :spread_expr
        AST::Spread.new(pair, parse_expr(pair.inner.first.stream))
      else
        raise "unexpected array item #{pair.rule.inspect} #{pair.text.inspect}"
      end
    end

    def parse_object(pair)
      AST::Object.new(pair, pair.map { |item| parse_object_item(item) })
    end

    def parse_object_item(pair)
      case pair
      in :object_item, [[:single_quoted | :double_quoted, _], expr]
        AST::Item.new(pair, parse_string(pair.inner.first), parse_expr(expr.stream))
      in :object_item, [name, expr]
        AST::Item.new(pair, AST::Name.new(name, name.text), parse_expr(expr.stream))
      in :object_item, [spread]
        AST::Spread.new(spread, parse_expr(spread.inner.first.stream))
      end
    end

    def parse_variable(pair)
      name, *segments = pair.children
      AST::Variable.new(pair, name.text, segments.map { |s| parse_variable_segment(s) })
    end

    def parse_variable_segment(pair)
      case pair.rule
      when :name
        AST::Name.new(pair, pair.text)
      when :double_quoted, :single_quoted
        parse_string(pair)
      when :expr
        parse_expr(pair.stream)
      when :predicate
        AST::Predicate.new(pair, pair.text)
      else
        raise "unexpected variable segment #{pair.rule.inspect} #{pair.text.inspect}"
      end
    end

    def parse_range(pair)
      start, stop = pair.children
      AST::Range.new(pair, parse_expr(start.stream), parse_expr(stop.stream))
    end

    def parse_keyword_arg(pair)
      name, arg = pair.children
      AST::KeywordArg.new(pair, name.text, parse_expr(arg.stream))
    end

    def parse_filter(pair)
      name, *args = pair.children
      AST::Filter.new(pair, name.text, args.map { |arg| parse_expr(arg.stream) })
    end

    def parse_lambda(pair)
      parameters, expr = pair.children
      params = parameters.map { |param| AST::Name.new(param, param.text) }
      AST::Lambda.new(pair, params, parse_expr(expr.stream))
    end

    def parse_ternary(pair)
      case pair
      in :ternary_expr | :arg_ternary_expr, [consequence]
        parse_expr(consequence.stream)
      in :ternary_expr | :arg_ternary_expr, [consequence, condition, alternative]
        AST::Ternary.new(
          pair,
          parse_expr(consequence.stream),
          parse_expr(condition.stream),
          parse_expr(alternative.stream)
        )
      else
        raise "malformed ternary expression #{pair.text.inspect}"
      end
    end
  end
end
