# frozen_string_literal: true

adapter = Isolator.isolate :vcr,
  exception_class: Isolator::HTTPError,
  details_message: ->(request) {
                     "#{request.method.to_s.upcase} #{request.uri}"
                   }

VCR.configure do |c|
  c.after_http_request do |request, _response|
    # check if we are even notifying before calling `caller`, which is well known to be slow
    adapter.notify(caller, request) if adapter.notify?(request)
  end
end
