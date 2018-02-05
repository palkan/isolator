# frozen_string_literal: true

module Isolator
  class Config < Anyway::Config
    attr_config raise_exceptions: true, send_notifications: false
  end
end
