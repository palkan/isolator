# frozen_string_literal: true

if defined?(::HTTP::Client)
  HTTP::Client.include Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
end
