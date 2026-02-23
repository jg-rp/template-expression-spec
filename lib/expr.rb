# frozen_string_literal: true

require_relative "expr/parser"

module Expr
  GRAMMAR = Pathname.new("expression.pest")

  PRATT_PARSER = Parser.new(Pestle::Parser.from_grammar(GRAMMAR.read))

  def self.parse(expr)
    PRATT_PARSER.parse(expr)
  end
end
