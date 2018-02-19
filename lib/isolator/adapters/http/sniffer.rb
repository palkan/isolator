# frozen_string_literal: true

require "sniffer"

# Disable Sniffer logger
Sniffer::Config.defaults["logger"] = Logger.new(IO::NULL)

Isolator.isolate :http, target: Sniffer.singleton_class,
                        method_name: :store,
                        exception_class: Isolator::HTTPError

Isolator.before_isolate do
  next if Isolator.adapters.http.disabled?
  Sniffer.enable!
end

Isolator.after_isolate do
  next if Isolator.adapters.http.disabled?
  Sniffer.clear!
  Sniffer.disable!
end
