# frozen_string_literal: true

if defined?(ActiveSupport)
  ActiveSupport.on_load(:action_mailer) do
    require "isolator/adapters/mailers/mail"
  end
end

require "isolator/adapters/mailers/mail" if defined?(Mail::Message)
