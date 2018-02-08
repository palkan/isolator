# frozen_string_literal: true
HTTPClient.include Isolator::AdapterBuilder.new(:do_get_block, ::Isolator::NetworkRequestError)
