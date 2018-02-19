# frozen_string_literal: true

adapter = Isolator.isolate :webmock, exception_class: Isolator::HTTPError

WebMock.after_request do |*args|
  adapter.notify(caller, *args)
end
