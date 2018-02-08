# frozen_string_literal: true
HTTP::Client.prepend Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
