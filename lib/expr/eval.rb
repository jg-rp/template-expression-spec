# frozen_string_literal: true

require "bigdecimal"
require "json"
require_relative "ast"

module Expr
  RE_INTEGER = /\A-?\d+(?:[eE]\+?\d+)?\Z/
  RE_DECIMAL = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/

  def self.evaluate(e, context)
    case e
    when AST::Ternary
      if truthy?(evaluate(e.condition, context))
        evaluate(e.expr, context)
      else
        evaluate(e.else, context)
      end
    when AST::Filtered
      apply_filter(e, context)
    when AST::Coalesce
      left = evaluate(e.left, context)
      left == :nothing ? evaluate(e.right, context) : left
    when AST::Or
      left = evaluate(e.left, context)
      truthy?(left) ? left : evaluate(e.right, context)
    when AST::And
      left = evaluate(e.left, context)
      truthy?(left) ? evaluate(e.right, context) : left
    when AST::Not
      !truthy?(evaluate(e.right, context))
    when AST::Eq
      eq?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::Ne
      !eq?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::Lt
      lt?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::Le
      lt?(evaluate(e.left, context), evaluate(e.right, context)) ||
        eq?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::Gt
      lt?(evaluate(e.right, context), evaluate(e.left, context))
    when AST::Ge
      lt?(evaluate(e.right, context), evaluate(e.left, context)) ||
        eq?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::Contains
      contains?(evaluate(e.left, context), evaluate(e.right, context))
    when AST::In
      contains?(evaluate(e.right, context), evaluate(e.left, context))
    when AST::Add
      lhs = to_number(evaluate(e.left, context))
      rhs = to_number(evaluate(e.right, context))
      lhs == :nothing || rhs == :nothing ? :nothing : lhs + rhs
    when AST::Sub
      lhs = to_number(evaluate(e.left, context))
      rhs = to_number(evaluate(e.right, context))
      lhs == :nothing || rhs == :nothing ? :nothing : lhs - rhs
    when AST::Mul
      lhs = to_number(evaluate(e.left, context))
      rhs = to_number(evaluate(e.right, context))
      lhs == :nothing || rhs == :nothing ? :nothing : lhs * rhs
    when AST::Div
      lhs = to_number(evaluate(e.left, context))
      rhs = to_number(evaluate(e.right, context))
      lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs / rhs
    when AST::Mod
      lhs = to_number(evaluate(e.left, context))
      rhs = to_number(evaluate(e.right, context))
      lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs % rhs
    when AST::Pos
      to_number(evaluate(e.right, context))
    when AST::Neg
      rhs = to_number(evaluate(e.right, context))
      rhs == :nothing ? rhs : -rhs
    when AST::Null
      nil
    when AST::Integer, AST::Float, AST::Boolean, AST::Name
      e.value
    when AST::String
      e.segments.map { |s| s.is_a?(::String) ? s : evaluate(s, context) }.join
    when AST::Array
      result = []
      e.items.each do |item|
        if item.is_a?(AST::Spread)
          result.concat(to_array(evaluate(item.expr, context)))
        else
          result << evaluate(item, context)
        end
      end
      result
    when AST::Object
      result = {}
      e.items.each do |item|
        if item.is_a?(AST::Spread)
          result.merge!(to_object(evaluate(item.expr, context)))
        else
          result[evaluate(item.key, context)] = evaluate(item.expr, context)
        end
      end
      result
    when AST::Range
      start = to_number(evaluate(e.start, context))
      stop = to_number(evaluate(e.stop, context))
      if start == :nothing || stop == :nothing
        []
      else
        (start...stop).to_a
      end
    when AST::Variable
      context.resolve(e.root, e.segments.map { |segment| evaluate(segment, context) })
    when AST::Predicate
      context.predicates[e.value]
    when AST::Lambda
      # TODO:
      raise "not implemented"
    else
      raise "unexpected node #{e.inspect}"
    end
  end

  def self.to_boolean(value)
    case value
    when :nothing, nil
      false
    when true, false
      value
    when ::Integer, ::Float
      !value.zero?
    when ::String, ::Array, ::Hash
      value.size.positive?
    else
      raise "unknown value for boolean conversion #{value.inspect}"
    end
  end

  def self.to_number(value)
    case value
    when ::Float
      BigDecimal(value)
    when Numeric
      value
    when ::String
      case value
      when RE_INTEGER
        value.to_f.to_i
      when RE_DECIMAL
        BigDecimal(value)
      else
        :nothing
      end
    when true
      1
    when false, nil, :nothing, ::Array, ::Hash
      :nothing
    else
      value.respond_to?(:to_liquid) ? value.to_liquid(:numeric) : :nothing
    end
  end

  def self.to_string(value)
    case value
    when ::Sting
      value
    when ::Hash, ::Array
      JSON.generate(value)
    when nil, :nothing
      ""
    when BigDecimal
      value.to_s("F")
    else
      value.to_s
    end
  end

  def self.to_array(value)
    case value
    when ::Array
      value
    when nil, :nothing
      []
    when ::Hash, ::String
      [value]
    else
      value.respond_to?(:each) ? value.each : [value]
    end
  end

  def self.to_object(value)
    if value.is_a?(Hash)
      value
    elsif value.respond_to?(:to_liquid)
      obj = value.to_liquid(:object)
      obj.is_a?(Hash) ? obj : {}
    else
      {}
    end
  end

  def self.truthy?(value)
    to_boolean(value)
  end

  def self.eq?(left, right)
    case [left, right]
    in [:nothing, :nothing] | [nil, nil]
      true
    in [:nothing, _] | [_, :nothing]
      false
    in [Numeric, Numeric] | [Array, Array] | [Hash, Hash] | [String, String] | [Boolean, Boolean]
      left == right
    else
      if left.respond_to?(:equals)
        left.equals(right) == true
      elsif right.respond_to?(:equals)
        right.equals(left) == true
      elsif left.respond_to?(:to_liquid) && right.respond_to?(:to_liquid)
        eq?(left.to_liquid(:default), right.to_liquid(:default))
      else
        false
      end
    end
  end

  def self.lt?(left, right)
    case [left, right]
    in [Numeric, Numeric] | [String, String]
      left < right
    else
      if left.respond_to?(:less_than)
        left.less_than(right) == true
      elsif right.respond_to?(:less_than)
        right.less_than(left) == true
      elsif left.respond_to?(:to_liquid) && right.respond_to?(:to_liquid)
        lt?(left.to_liquid(:default), right.to_liquid(:default))
      else
        false
      end
    end
  end

  def self.contains?(left, right)
    if left.respond_to?(:contains)
      left.contains(right) == true
    elsif left.is_a?(String) && right.is_a?(String)
      left.include?(right)
    elsif left.respond_to?(:iterate)
      left.iterate do |item|
        return true if eq?(item, right)
      end
      false
    elsif left.is_a?(Hash)
      left.key?(right)
    elsif left.respond_to?(:each)
      left.each do |item|
        return true if eq?(item, right)
      end
      false
    elsif left.respond_to(:to_liquid)
      if right.respond_to?(:to_liquid)
        contains?(left.to_liquid(:default), right.to_liquid(:default))
      else
        contains?(left.to_liquid(:default), right)
      end
    else
      false
    end
  end

  def self.apply_filter(e, context)
    filter = context.filters[e.filter.name]
    return :nothing if filter.nil?

    left = evaluate(e.left, context)

    args = []
    kw_args = {}

    e.filter.args.each do |arg|
      if arg.is_a?(AST::KeywordArg)
        kw_args[arg.name] = evaluate(arg.expr, context)
      else
        args << evaluate(arg, context)
      end
    end

    if kw_args.empty?
      filter.call(left, *args)
    else
      filter.call(left, *args, **kw_args)
    end
  rescue ArgumentError, TypeError
    :nothing
  end
end
