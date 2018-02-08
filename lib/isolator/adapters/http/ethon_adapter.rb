# frozen_string_literal: true
Ethon::Easy.prepend Isolator::AdapterBuilder.new(:http_request, ::Isolator::NetworkRequestError)
