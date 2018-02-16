# frozen_string_literal: true

ActiveSupport.on_load(:action_mailer) do
  Isolator.isolate :action_mailer, ActionMailer::Base.singleton_class,
                   :deliver_mail, exception_class: Isolator::ActionMailerError
end
