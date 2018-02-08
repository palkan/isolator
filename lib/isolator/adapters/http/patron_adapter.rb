# frozen_string_literal: true
Patron::Session.prepend Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
