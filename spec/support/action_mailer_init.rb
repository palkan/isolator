# frozen_string_literal: true

require "action_mailer"

ActionMailer::Base.delivery_method = :test

class SampleEmail < ActionMailer::Base
  default from: "isolator@example.com"

  def hello
    mail(to: "example.com", subject: "isolator test", body: "isolator test")
  end
end
