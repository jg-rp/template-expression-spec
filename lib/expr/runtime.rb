# frozen_string_literal: true

require "bigdecimal"
require "json"

module Expr
  RE_INTEGER = /\A-?\d+(?:[eE]\+?\d+)?\Z/
  RE_DECIMAL = /((?:-?\d+\.\d+(?:[eE][+-]?\d+)?)|(-?\d+[eE]-\d+))/

  Lambda = Data.define(:params, :expr, :context) do
    def broadcast(enum)
      scope = {}
      result = []

      if params.length == 1
        param = params.first

        context.extend(scope) do
          enum.each do |item|
            scope[param] = item
            result << expr.evaluate(context)
          end
        end
      else
        name_param = params.first
        index_param = params[1]

        context.extend(scope) do
          enum.each_with_index do |item, index|
            scope[index_param] = index
            scope[name_param] = item
            result << expr.evaluate(context)
          end
        end
      end

      result
    end

    def call(value, index)
      scope = { params.first => value }
      scope[params[1]] = index if params.length > 1

      context.extend(scope) do
        return expr.evaluate(context)
      end
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
    when ::Float
      BigDecimal(value)
    when Numeric
      value
    when ::String
      case value
      when RE_INTEGER
        value.to_f.to_i
      when RE_DECIMAL
        BigDecimal(value)
      else
        :nothing
      end
    when true
      1
    when false
      0
    when nil, :nothing, ::Array, ::Hash
      :nothing
    else
      value.respond_to?(:to_liquid) ? value.to_liquid(:numeric) : :nothing
    end
  end

  def self.to_string(value)
    case value
    when ::String
      value
    when ::Hash, ::Array
      JSON.generate(value)
    when nil, :nothing
      ""
    when BigDecimal
      value.to_s("F")
    else
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

  def self.to_object(value)
    if value.is_a?(Hash)
      value
    elsif value.respond_to?(:to_liquid)
      obj = value.to_liquid(:object)
      obj.is_a?(Hash) ? obj : {}
    else
      {}
    end
  end

  def self.to_enumerable(obj)
    if obj.respond_to?(:iterate)
      obj.iterate
    else
      to_array(obj)
    end
  end

  def self.truthy?(value)
    to_boolean(value)
  end

  def self.eq?(left, right)
    case [left, right]
    in [:nothing, :nothing] | [nil, nil]
      true
    in [:nothing, _] | [_, :nothing]
      false
    in [Numeric, Numeric] | [Array, Array] | [Hash, Hash] | [String, String] | [Boolean, Boolean]
      left == right
    else
      if left.respond_to?(:equals)
        left.equals(right) == true
      elsif right.respond_to?(:equals)
        right.equals(left) == true
      elsif left.respond_to?(:to_liquid) && right.respond_to?(:to_liquid)
        eq?(left.to_liquid(:default), right.to_liquid(:default))
      else
        false
      end
    end
  end

  def self.lt?(left, right)
    case [left, right]
    in [Numeric, Numeric] | [String, String]
      left < right
    else
      if left.respond_to?(:less_than)
        left.less_than(right) == true
      elsif right.respond_to?(:less_than)
        right.less_than(left) == true
      elsif left.respond_to?(:to_liquid) && right.respond_to?(:to_liquid)
        lt?(left.to_liquid(:default), right.to_liquid(:default))
      else
        false
      end
    end
  end

  def self.contains?(left, right)
    if left.respond_to?(:contains)
      left.contains(right) == true
    elsif left.is_a?(String) && right.is_a?(String)
      left.include?(right)
    elsif left.respond_to?(:iterate)
      left.iterate do |item|
        return true if eq?(item, right)
      end
      false
    elsif left.is_a?(Hash)
      left.key?(right)
    elsif left.respond_to?(:each)
      left.each do |item|
        return true if eq?(item, right)
      end
      false
    elsif left.respond_to(:to_liquid)
      if right.respond_to?(:to_liquid)
        contains?(left.to_liquid(:default), right.to_liquid(:default))
      else
        contains?(left.to_liquid(:default), right)
      end
    else
      false
    end
  end
end
