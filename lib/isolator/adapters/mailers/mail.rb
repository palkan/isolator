# frozen_string_literal: true

Isolator.isolate :mailer, target: Mail::Message, method_name: :deliver,
                          exception_class: Isolator::MailerError
