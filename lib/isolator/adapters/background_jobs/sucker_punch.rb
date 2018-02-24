# frozen_string_literal: true

Isolator.isolate :sucker_punch,
                 target: SuckerPunch::Queue.singleton_class,
                 method_name: :find_or_create,
                 exception_class: Isolator::BackgroundJobError
