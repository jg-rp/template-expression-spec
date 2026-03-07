# frozen_string_literal: true

require "json"
require_relative "expr/parser"
require_relative "expr/runtime"
require_relative "expr/context"

module Expr
  GRAMMAR = Pathname.new("expression.pest")

  PEST_PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  PRATT_PARSER = Parser.new(PEST_PARSER)

  def self.parse(expr)
    PRATT_PARSER.parse(expr)
  end

  def self.evaluate(expr, data)
    ast = parse(expr)
    ast.evaluate(Context.new(data))
  end

  def self.render(expr, data)
    to_output_s(evaluate(expr, data))
  end

  # Return `value` as a string suitable for rendering to output.
  def self.to_output_s(value)
    case value
    when Hash, Array
      JSON.generate(value)
    when BigDecimal
      value.to_f.to_s
    when :nothing
      ""
    else
      value.to_s
    end
  end
end
