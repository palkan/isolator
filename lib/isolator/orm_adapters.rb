# frozen_string_literal: true

if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_record) do
    require "isolator/orm_adapters/active_record"
  end

  require "isolator/orm_adapters/rom_active_support" if
    defined?(::ROM::SQL::ActiveSupportInstrumentation)
end
