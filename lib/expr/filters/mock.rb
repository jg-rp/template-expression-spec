# frozen_string_literal: true

require "bigdecimal/util"

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
      return :nothing if lhs == :nothing || rhs == :nothing || rhs.zero?

      result = lhs.to_d / rhs
      result.frac.zero? && lhs.is_a?(::Integer) && rhs.is_a?(::Integer) ? result.to_i : result
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
      return :nothing if lhs == :nothing || rhs == :nothing || rhs.zero?

      result = lhs.to_d % rhs
      result.frac.zero? && lhs.is_a?(::Integer) && rhs.is_a?(::Integer) ? result.to_i : result
    end

    def self.plus(left, right)
      lhs = Expr.to_number(left)
      rhs = Expr.to_number(right)
      lhs == :nothing || rhs == :nothing ? :nothing : lhs + rhs
    end

    def self.map(left, lambda)
      lambda.broadcast(Expr.to_enumerable(left))
    end

    def self.find(left, lambda)
      Expr.to_enumerable(left).each_with_index do |item, index|
        return item if Expr.truthy?(lambda.call(item, index))
      end
    end

    def self.join(left, sep = " ")
      Expr.to_enumerable(left).map { |i| Expr.to_string(i) }.join(Expr.to_string(sep))
    end

    def self.split(left, pattern)
      Expr.to_string(left).split(Expr.to_string(pattern))
    end

    def self.concat(left, right)
      [*Expr.to_enumerable(left), *Expr.to_enumerable(right)]
    end
  end
end
