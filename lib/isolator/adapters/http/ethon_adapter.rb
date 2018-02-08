# frozen_string_literal: true
Ethon::Easy.include Isolator::AdapterBuilder.new(:http_request, ::Isolator::NetworkRequestError)
