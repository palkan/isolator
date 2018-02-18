# frozen_string_literal: true

Isolator.isolate :sidekiq, Sidekiq::Client,
                 :raw_push, exception_class: Isolator::BackgroundJobError
