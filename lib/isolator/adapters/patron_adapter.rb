# frozen_string_literal: true

if defined?(::Patron::Session)
  ::Patron::Session.include Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
end
