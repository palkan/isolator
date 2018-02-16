# frozen_string_literal: true

patch = lambda {
  return if Isolator.adapters.key?("mailer")

  Isolator.isolate :mailer, Mail::Message,
                   :deliver, exception_class: Isolator::MailerError
}

ActiveSupport.on_load(:action_mailer) do
  patch.call
end

patch.call if defined?(Mail::Message)
