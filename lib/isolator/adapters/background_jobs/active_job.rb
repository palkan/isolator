# frozen_string_literal: true

adapter_name = -> { ActiveJob::Base.queue_adapter.class.name.demodulize.remove("Adapter") }

db_backend = -> { %w[Que QueClassic].include?(adapter_name.call) }

ar_delayed_job = lambda {
  adapter_name.call == "DelayedJob" &&
    Delayed::Worker.backend.name.match(/Delayed::Backend::(.*)::Job/)[1] == "ActiveRecord"
}

mod = Isolator::AdapterBuilder.new :enqueue,
                                   exception: Isolator::BackgroundJobError,
                                   unless: [db_backend, ar_delayed_job]

ActiveJob::Base.prepend mod
