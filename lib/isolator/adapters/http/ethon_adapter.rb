# frozen_string_literal: true

mod = Isolator::AdapterBuilder.new(:http_request, exception: ::Isolator::NetworkRequestError)
Ethon::Easy.prepend mod
