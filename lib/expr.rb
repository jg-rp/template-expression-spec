# frozen_string_literal: true

require_relative "expr/parser"
require_relative "expr/eval"
require_relative "expr/context"

module Expr
  GRAMMAR = Pathname.new("expression.pest")

  PEST_PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  PRATT_PARSER = Parser.new(PEST_PARSER)

  def self.parse(expr)
    PRATT_PARSER.parse(expr)
  end
end
