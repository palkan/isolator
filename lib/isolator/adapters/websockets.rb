# frozen_string_literal: true

if defined?(ActiveSupport)
  ActiveSupport.on_load(:action_cable) do
    require "isolator/adapters/websockets/action_cable"
  end
end
