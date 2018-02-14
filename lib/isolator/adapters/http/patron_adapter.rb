# frozen_string_literal: true

mod = Isolator::AdapterBuilder.new(:request, exception: ::Isolator::NetworkRequestError)
Patron::Session.prepend mod
