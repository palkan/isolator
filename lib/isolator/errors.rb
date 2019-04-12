# frozen_string_literal: true

module Isolator # :nodoc: all
  class UnsafeOperationError < StandardError
    MESSAGE = "You are trying to do unsafe operation inside db transaction"

    def initialize(msg = nil, details: nil)
      msg ||= self.class::MESSAGE
      super(details ? "#{msg}\nDetails: #{details}" : msg)
    end
  end

  class HTTPError < UnsafeOperationError
    MESSAGE = "You are trying to make an outgoing network request inside db transaction. "
  end

  class BackgroundJobError < UnsafeOperationError
    MESSAGE = "You are trying to enqueue background job inside db transaction. " \
      "In case of transaction failure, this may lead to data inconsistency and unexpected bugs"
  end

  class MailerError < UnsafeOperationError
    MESSAGE = "You are trying to send email inside db transaction."
  end
end
