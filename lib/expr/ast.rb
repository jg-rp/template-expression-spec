# frozen_string_literal: true

module Expr
  Expression = Data.define(:token, :expr)
  Ternary = Data.define(:token, :expr, :condition, :else)
  Filtered = Data.define(:token, :left, :filters)
  Coalesce = Data.define(:token, :left, :right)

  Or = Data.define(:token, :left, :right)
  And = Data.define(:token, :left, :right)
  Not = Data.define(:token, :right)

  Eq = Data.define(:token, :left, :right)
  Ne = Data.define(:token, :left, :right)
  Lt = Data.define(:token, :left, :right)
  Le = Data.define(:token, :left, :right)
  Gt = Data.define(:token, :left, :right)
  Ge = Data.define(:token, :left, :right)

  Contains = Data.define(:token, :left, :right)
  In = Data.define(:token, :left, :right)

  Add = Data.define(:token, :left, :right)
  Sub = Data.define(:token, :left, :right)
  Mul = Data.define(:token, :left, :right)
  Div = Data.define(:token, :left, :right)
  Mod = Data.define(:token, :left, :right)

  Integer = Data.define(:token, :value)
  Float = Data.define(:token, :value)
  String = Data.define(:token, :segments)
  Boolean = Data.define(:token, :segments)
  Null = Data.define(:token)
  Array = Data.define(:token, :items)
  Object = Data.define(:token, :items)
  Spread = Data.define(:token, :expr)
  Item = Data.define(:token, :key, :expr)

  Range = Data.define(:token, :start, :stop)
  Variable = Data.define(:token, :root, :segments)

  Filter = Data.define(:token, :name, :args)
  KeywordArg = Data.define(:token, :name, :expr)
end
