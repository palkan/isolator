# frozen_string_literal: true

require "isolator/adapters/http/sniffer"

require "isolator/adapters/http/vcr" if defined?(::VCR)
require "isolator/adapters/http/webmock" if defined?(::WebMock)
