# frozen_string_literal: true

require "sniffer"

Sniffer.config do |c|
  # Disable Sniffer logger
  c.logger = Logger.new(IO::NULL)
end

Isolator.isolate :http, target: Sniffer.singleton_class,
                        method_name: :store,
                        exception_class: Isolator::HTTPError

Isolator.before_isolate do
  Sniffer.enable!
end

Isolator.after_isolate do
  Sniffer.clear!
  Sniffer.disable!
end
