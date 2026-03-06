# frozen_string_literal: true

module Expr
  module Predicates
    def self.defined?(value)
      value != :nothing
    end

    def self.blank?(value)
      case value
      when nil
        true
      when String
        value.strip == ""
      when Array, Object
        value.empty?
      else
        value.respond_to?(:length) ? value.length.zero? : false
      end
    end

    def self.empty?(value)
      case value
      when Array, Object, String
        value.empty?
      else
        value.respond_to?(:length) ? value.length.zero? : false
      end
    end
  end
end
