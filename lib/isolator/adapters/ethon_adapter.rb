# frozen_string_literal: true

if defined?(::Ethon::Easy)
  Ethon::Easy.include Isolator::AdapterBuilder.new(:http_request, ::Isolator::NetworkRequestError)
end
