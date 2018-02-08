# frozen_string_literal: true
HTTP::Client.include Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
