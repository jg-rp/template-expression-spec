# frozen_string_literal: true

require "json"
require_relative "ast"

module Expr
  def self.evaluate(e, context)
    case e
    when Ternary
      if truthy?(evaluate(e.condition, context))
        evaluate(e.expr, context)
      else
        evaluate(e.else, context)
      end
    when Filtered
      apply_filter(e)
    when Coalesce
      left = evaluate(e.left, context)
      nothing?(left) ? evaluate(e.right, context) : left
    when Or
      left = evaluate(e.left, context)
      truthy?(left) ? left : evaluate(e.right, context)
    when And
      left = evaluate(e.left, context)
      truthy?(left) ? evaluate(e.right, context) : left
    when Not
      !truthy?(evaluate(e.right, context))
    when Eq
      eq?(evaluate(e.left, context), evaluate(e.right, context))
    when Ne
      !eq?(evaluate(e.left, context), evaluate(e.right, context))
    when Lt
      lt?(evaluate(e.left, context), evaluate(e.right, context))
    when Le
      lt?(evaluate(e.left, context),
          evaluate(e.right, context)) || eq?(evaluate(e.left, context), evaluate(e.right, context))
    when Gt
      lt?(evaluate(e.right, context), evaluate(e.left, context))
    when Ge
      lt?(evaluate(e.right, context),
          evaluate(e.left, context)) || eq?(evaluate(e.left, context), evaluate(e.right, context))
    when Contains
      contains?(evaluate(e.left, context), evaluate(e.right, context))
    when In
      contains?(evaluate(e.right, context), evaluate(e.left, context))
    when Add, Sub, Mul, Div, Mod, Pos, Neg
      # TODO: Conversion functions
      raise "not implemented"
    when Null
      nil
    when Integer, Float, Boolean
      e.value
    when String
      e.segments.map { |s| s.is_a?(::String) ? s : evaluate(s, context) }
    when Array, Object
      # TODO:
      raise "not implemented!"
    when Range
      # TODO: Conversion functions
      raise "not implemented!"
    when Variable
      # TODO: resolve
      raise "not implemented!"
    end
  end

  def self.to_boolean(value)
    case value
    when Nothing, nil
      false
    when true, false
      value
    when Integer, Float
      !value.zero?
    when String, Array, Hash
      value.size.positive?
    else
      raise "unknown value for boolean conversion #{value.inspect}"
    end
  end

  def self.to_number(value)
    case value
    when Integer, Float # TODO: BigDecimal, Numeric
      value
    when true
      1
    when false, nil, Nothing, Array, Hash
      0
    when String
      begin
        obj.match?(/\A-?\d+(?:[eE]\+?\d+)?\Z/) ? obj.to_f.to_i : Float(obj)
      rescue ArgumentError
        0
      end
    end
  end

  def self.to_string(value)
    case value
    when Sting
      value
    when Hash, Array
      JSON.generate(value)
    when nil, Nothing
      ""
    else
      # TODO: BigDecimal
      value.to_s
    end
  end

  def self.to_array(value)
    case value
    when Array
      value
    when nil, Nothing
      []
    when Hash, String
      [value]
    else
      value.respond_to?(:each) ? value.each : [value]
    end
  end

  def self.nothing?(value)
    value.instance_of?(Nothing)
  end

  def self.truthy?(value)
    to_boolean(value)
  end

  def self.eq?(left, right)
    # TODO:
    raise "not implemented"
  end

  def self.lt?(left, right)
    # TODO:
    raise "not implemented"
  end

  def self.contains?(left, right)
    # TODO:
    raise "not implemented"
  end

  def self.apply_filter(expr)
    # TODO:
    raise "not implemented"
  end
end
