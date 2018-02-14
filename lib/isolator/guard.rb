# frozen_string_literal: true

module Isolator
  class Guard
    attr_reader :object

    def initialize(object:, conditions:)
      @object = object
      @if = Array(conditions[:if])
      @unless = Array(conditions[:unless])
    end

    def notify?
      Isolator.enabled? && \
        @if.all? { |c| call_condition c } && \
        @unless.none? { |c| call_condition c }
    end

    private

    def call_condition(condition)
      case condition
      when Proc
        condition.call
      when Symbol, String
        object.send(condition)
      else
        raise ArgumentError, "Expected a method name or a Proc"
      end
    end
  end
end
