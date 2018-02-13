# frozen_string_literal: true

module Isolator
  class Config
    attr_accessor :raise_exceptions, :send_notifications

    def initialize
      @raise_exceptions = true
      @send_notifications = false
    end
  end
end
