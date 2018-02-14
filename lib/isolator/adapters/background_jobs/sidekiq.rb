# frozen_string_literal: true

Isolator.isolate :sidekiq, Sidekiq::Client,
                 :push, exception_class: Isolator::BackgroundJobError
