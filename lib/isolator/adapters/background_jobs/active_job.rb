# frozen_string_literal: true

Isolator.isolate :active_job, ActiveJob::Base,
                 :enqueue, exception_class: Isolator::BackgroundJobError
