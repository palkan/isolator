# frozen_string_literal: true

Patron::Session.include Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
