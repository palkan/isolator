ActiveJob::Base.prepend Isolator::AdapterBuilder.new(%i(perform_now enqueue), Isolator::BackgroundJobError)
