# frozen_string_literal: true

mod = Isolator::AdapterBuilder.new(:perform_now, :enqueue, exception: Isolator::BackgroundJobError)
ActiveJob::Base.prepend mod
