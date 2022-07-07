# frozen_string_literal: true

Isolator.isolate :active_job,
  target: ActiveJob::Base,
  method_name: :enqueue,
  exception_class: Isolator::BackgroundJobError,
  details_message: ->(obj) {
    "#{obj.class.name}" \
    "#{obj.arguments.any? ? " (#{obj.arguments.join(", ")})" : ""}"
  }
