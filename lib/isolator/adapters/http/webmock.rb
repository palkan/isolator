# frozen_string_literal: true

adapter = Isolator.isolate :webmock,
                           exception_class: Isolator::HTTPError,
                           details_message: ->(obj, _args) {
                                              "#{obj.method.to_s.upcase} #{obj.uri}"
                                            }

WebMock.after_request do |*args|
  adapter.notify(caller, *args)
end
