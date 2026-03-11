# frozen_string_literal: true

require_relative "predicates/mock"
require_relative "filters/mock"
require_relative "scope"

module Expr
  class Context
    attr_reader :filters, :predicates

    def initialize(data)
      @data = data
      @scope = ReadOnlyChainHash.new(@data)
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
      @filters["find"] = Filters.method(:find)
      @filters["join"] = Filters.method(:join)
      @filters["split"] = Filters.method(:split)
      @filters["concat"] = Filters.method(:concat)
      @filters["compact"] = Filters.method(:compact)
      @filters["upcase"] = Filters.method(:upcase)
      @filters["append"] = Filters.method(:append)
    end

    def setup_predicates
      @predicates["defined?"] = Predicates.method(:defined?)
      @predicates["blank?"] = Predicates.method(:blank?)
      @predicates["empty?"] = Predicates.method(:empty?)
    end

    def resolve(name, segments)
      obj = @scope.fetch(name)
      resolve_path(obj, segments)
    end

    def resolve_path(obj, segments)
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
                # A predicate?
                segment.respond_to?(:call) ? segment.call(obj) : :nothing
              end
      end

      obj
    end

    def extend(namespace)
      @scope << namespace
      yield
    ensure
      @scope.pop
    end
  end
end
