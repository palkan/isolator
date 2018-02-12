# frozen_string_literal: true

mod = Isolator::AdapterBuilder.new(:push, exception: Isolator::BackgroundJobError)
Sidekiq::Client.prepend mod
