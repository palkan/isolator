# frozen_string_literal: true

if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_record) do
    require "isolator/orm_adapters/active_record"
  end
end