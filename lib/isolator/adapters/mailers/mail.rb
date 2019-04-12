# frozen_string_literal: true

Isolator.isolate :mailer, target: Mail::Message,
                          method_name: :deliver,
                          exception_class: Isolator::MailerError,
                          details_message: ->(obj, _args) {
                            "From: #{obj.from}\n" \
                            "To: #{obj.to}\n" \
                            "Subject: #{obj.subject}"
                          }
