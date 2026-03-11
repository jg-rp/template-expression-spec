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
    to_string(evaluate(expr, data))
  end
end
