# frozen_string_literal: true

Isolator.isolate :resque,
                 target: Resque.singleton_class,
                 method_name: :enqueue,
                 exception_class: Isolator::BackgroundJobError
