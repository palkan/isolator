# frozen_string_literal: true

Isolator.isolate :action_mailer, ActionMailer::Base,
                 :mail, exception_class: Isolator::ActionMailerError
