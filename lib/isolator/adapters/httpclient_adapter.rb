# frozen_string_literal: true

if defined?(::HTTPClient)
  HTTPClient.include Isolator::AdapterBuilder.new(:do_get_block, ::Isolator::NetworkRequestError)
end
