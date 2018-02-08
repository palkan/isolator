# frozen_string_literal: true
Net::HTTP.prepend Isolator::AdapterBuilder.new(:request, ::Isolator::NetworkRequestError)
