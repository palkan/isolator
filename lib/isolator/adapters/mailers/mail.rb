# frozen_string_literal: true

Isolator.isolate :mailer, Mail::Message, :deliver,
                 exception_class: Isolator::MailerError
