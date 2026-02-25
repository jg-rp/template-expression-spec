# frozen_string_literal: true

require_relative "ast"

module Expr
  def self.evaluate(e, context)
    case e
    when Expression
      evaluate(e.expr, context)
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

  def self.nothing?(value)
    value.instance_of?(Nothing)
  end

  def truthy?(value)
    # TODO:
    raise "not implemented"
  end

  def eq?(left, right)
    # TODO:
    raise "not implemented"
  end

  def lt?(left, right)
    # TODO:
    raise "not implemented"
  end

  def contains?(left, right)
    # TODO:
    raise "not implemented"
  end

  def apply_filter(expr)
    # TODO:
    raise "not implemented"
  end
end
