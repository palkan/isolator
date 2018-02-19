# frozen_string_literal: true

Isolator.isolate :active_job,
                 target: ActiveJob::Base,
                 method_name: :enqueue,
                 exception_class: Isolator::BackgroundJobError
