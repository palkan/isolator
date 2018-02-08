# frozen_string_literal: true

mod = Isolator::AdapterBuilder.new(:do_get_block,exception: ::Isolator::NetworkRequestError)
HTTPClient.prepend mod
