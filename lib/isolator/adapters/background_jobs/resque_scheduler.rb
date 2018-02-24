# frozen_string_literal: true

Isolator.isolate :resque_scheduler,
                 target: Resque.singleton_class,
                 method_name: :enqueue_at,
                 exception_class: Isolator::BackgroundJobError
