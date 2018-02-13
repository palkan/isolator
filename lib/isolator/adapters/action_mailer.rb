module Isolator
  module Adapters
    module ActionMailer
      def self.included(base)
        base.class_eval do
          alias_method :orig_mail, :mail
          alias_method :mail, :mail_with_isolator
        end
      end

      def mail_with_isolator(headers = {}, &block)
        Isolator.analyzers[:action_mailer].register_usage
        orig_mail(headers, &block)
      end
    end
  end
end

ActionMailer::Base.send(:include, Isolator::Adapters::ActionMailer) if defined?(ActionMailer)
