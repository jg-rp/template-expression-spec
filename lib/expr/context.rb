# frozen_string_literal: true

require_relative "predicates/mock"
require_relative "filters/mock"

module Expr
  class Context
    attr_reader :filters, :predicates

    def initialize(data)
      @data = data
      @filters = {}
      @predicates = {}

      setup_filters
      setup_predicates
    end

    def setup_filters
      @filters["abs"] = Filters.method(:abs)
      @filters["at_least"] = Filters.method(:at_least)
      @filters["at_most"] = Filters.method(:at_most)
      @filters["ceil"] = Filters.method(:ceil)
      @filters["divided_by"] = Filters.method(:divided_by)
      @filters["floor"] = Filters.method(:floor)
      @filters["minus"] = Filters.method(:minus)
      @filters["modulo"] = Filters.method(:modulo)
      @filters["plus"] = Filters.method(:plus)
      @filters["times"] = Filters.method(:times)
      @filters["map"] = Filters.method(:map)
    end

    def setup_predicates
      @predicates["defined?"] = Predicates.method(:defined?)
      @predicates["blank?"] = Predicates.method(:blank?)
      @predicates["empty?"] = Predicates.method(:empty?)
    end

    def resolve(name, segments)
      # TODO: scope for lambda expr
      obj = @data.key?(name) ? @data[name] : :nothing

      # NOTE: We're not returning or breaking early because there might be a
      # trailing predicate.

      segments.each do |segment|
        obj = case segment
              when String
                if obj.respond_to?(:key?) && obj.key?(segment)
                  obj[segment]
                else
                  :nothing
                end
              when Integer
                if obj.respond_to?(:fetch)
                  obj[segment]
                else
                  :nothing
                end
              else
                # A predicate
                segment.respond_to?(:call) ? segment.call(obj) : :nothing
              end
      end

      obj
    end
  end
end
