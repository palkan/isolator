# frozen_string_literal: true
HTTPClient.prepend Isolator::AdapterBuilder.new(:do_get_block, ::Isolator::NetworkRequestError)
