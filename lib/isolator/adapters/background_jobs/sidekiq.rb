# frozen_string_literal: true

Isolator.isolate :sidekiq,
                 target: Sidekiq::Client,
                 method_name: :raw_push,
                 exception_class: Isolator::BackgroundJobError,
                 details_message: ->(_obj, args) {
                   args.first.map do |job|
                     "#{job['class']} (#{job['args']})"
                   end.join("\n")
                 }
