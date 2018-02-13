module Isolator
  module Errors
    class ActionMailerUsage < StandardError
      def to_s
        "ActionMailer usage within transaction not allowed!"
      end
    end
  end
end
