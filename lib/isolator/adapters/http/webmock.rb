# frozen_string_literal: true

adapter = Isolator.isolate :webmock,
  exception_class: Isolator::HTTPError,
  details_message: ->(obj) {
                     "#{obj.method.to_s.upcase} #{obj.uri}"
                   }

WebMock.after_request do |*args|
  # check if we are even notifying before calling `caller`, which is well known to be slow
  adapter.notify(caller, *args) if adapter.notify?(*args)
end
