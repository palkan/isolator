# frozen_string_literal: true

Isolator.isolate :sidekiq,
                 target: Sidekiq::Client,
                 method_name: :raw_push,
                 exception_class: Isolator::BackgroundJobError
