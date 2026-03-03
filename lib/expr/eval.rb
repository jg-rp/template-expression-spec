# frozen_string_literal: true

require "json"
require_relative "ast"

module Expr
  def self.evaluate(e, context)
    case e
    when AST::Ternary
      if truthy?(evaluate(e.condition, context))
        evaluate(e.expr, context)
      else
        evaluate(e.else, context)
      end
    when AST::Filtered
      apply_filter(e)
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
          obj = evaluate(item.expr, context)
          # XXX: Spread of non-hash is a no-op
          if obj.is_a?(Hash)
            result.merge!(obj)
          elsif obj.respond_to?(:to_h)
            result.merge!(obj.to_h)
          end
        else
          key = evaluate(item.key, context)
          result[key] = evaluate(item.expr, context)
        end
      end
      result
    when AST::Range
      # TODO: Lazy range drop?
      raise "not implemented!"
    when AST::Variable
      # TODO: resolve
      raise "not implemented!"
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
    when ::Integer, ::Float # TODO: BigDecimal, Numeric
      value
    when true
      1
    when false, nil, :nothing, ::Array, ::Hash
      :nothing
    when ::String
      begin
        value.match?(/\A-?\d+(?:[eE]\+?\d+)?\Z/) ? value.to_f.to_i : Float(value)
      rescue ::ArgumentError
        :nothing
      end
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
    else
      # TODO: BigDecimal
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
