# frozen_string_literal: true

Isolator.isolate :active_job,
  target: ActiveJob::Base,
  method_name: :enqueue,
  exception_class: Isolator::BackgroundJobError,
  details_message: ->(obj) {
    "#{obj.class.name}" \
    "#{" (#{obj.arguments.join(", ")})" if obj.arguments.any?}"
  },
  ignore_on: ->(job) {
               config = job.class.try(:enqueue_after_transaction_commit)
               config == true
             }
