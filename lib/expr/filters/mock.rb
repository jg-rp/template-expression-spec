# frozen_string_literal: true

module Expr
  module Filters
    def self.abs(left)
      lhs = Expr.to_number(left)
      lhs == :nothing ? :nothing : lhs.abs
    end

    def self.at_least(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : [lhs, rhs].max
    end

    def self.at_most(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : [lhs, rhs].min
    end

    def self.ceil(left)
      lhs = Expr.to_number(left)
      lhs == :nothing ? :nothing : lhs.ceil
    end

    def self.divided_by(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs / rhs
    end

    def self.times(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : lhs * rhs
    end

    def self.floor(left)
      lhs = Expr.to_number(left)
      lhs == :nothing ? :nothing : lhs.floor
    end

    def self.minus(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : lhs - rhs
    end

    def self.modulo(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing || rhs.zero? ? :nothing : lhs % rhs
    end

    def self.plus(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : lhs + rhs
    end

    def self.map(left, key)
      raise "not implemented"
    end
  end
end
