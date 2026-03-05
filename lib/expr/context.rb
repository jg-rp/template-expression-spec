# frozen_string_literal: true

module Expr
  class Context
    def initialize(data)
      @data = data
      @filters = {}
      setup_filters
    end

    def setup_filters
    end

    def resolve(name, segments)
      obj = @data.key?(name) ? @data[name] : :nothing
      return obj if obj == :nothing

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
                :nothing
              end

        break if obj == :nothing
      end

      obj
    end
  end
end
