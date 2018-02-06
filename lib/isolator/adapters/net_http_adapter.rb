# frozen_string_literal: true

Net::HTTP.include Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
