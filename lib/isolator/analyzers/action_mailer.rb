module Isolator
  module Analyzers
    class ActionMailer < Base
      class << self
        attr_accessor :mailer_usages_count
      end

      def start
        self.class.mailer_usages_count = 0
      end

      def register_usage
        self.class.mailer_usages_count += 1
      end

      def infer!
        handle_errors! if emails_was_sent?
      end

      private

      def emails_was_sent?
        self.class.mailer_usages_count > 0
      end

      def handle_errors!
        if Isolator.configuration.logger
          Isolator.logger.debug("ActionMailer usage within transaction not allowed!")
        end

        if Isolator.configuration.raise_errors
          raise Errors::ActionMailerUsage
        end
      end
    end
  end
end
