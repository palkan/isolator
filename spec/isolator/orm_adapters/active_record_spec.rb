# frozen_string_literal: true

require "spec_helper"

describe "ActiveRecord integration" do
  let(:ar_class) { User }

  describe ".transaction" do
    after { expect(Isolator).to_not be_within_transaction }

    context "HTTP requests" do
      subject do
        ar_class.transaction do
          Net::HTTP.get("example.com", "/index.html")
        end
      end

      it { expect { subject }.to raise_error(Isolator::HTTPError) }

      context "when adapter is disabled" do
        around do |ex|
          Isolator.adapters.http.disable!
          ex.run
          Isolator.adapters.http.enable!
        end

        it "doesn't raise" do
          expect { subject }.to_not raise_error
        end
      end

      context "when Isolator is disabled" do
        around do |ex|
          Isolator.disable!
          ex.run
          Isolator.enable!
        end

        it "doesn't raise" do
          expect { subject }.to_not raise_error
        end
      end
    end

    context "Background Jobs" do
      context "ActiveJob" do
        subject do
          ar_class.transaction do
            ActiveJobWorker.perform_later
          end
        end

        it { expect { subject }.to raise_error(Isolator::BackgroundJobError) }

        context "when adapter is disabled" do
          around do |ex|
            Isolator.adapters.active_job.disable!
            ex.run
            Isolator.adapters.active_job.enable!
          end

          it "doesn't raise" do
            expect { subject }.to_not raise_error
          end
        end
      end

      context "Sidekiq" do
        subject do
          ar_class.transaction do
            SidekiqWorker.perform_async
          end
        end

        it { expect { subject }.to raise_error(Isolator::BackgroundJobError) }

        context "when adapter is disabled" do
          around do |ex|
            Isolator.adapters.sidekiq.disable!
            ex.run
            Isolator.adapters.sidekiq.enable!
          end

          it "doesn't raise" do
            expect { subject }.to_not raise_error
          end
        end
      end
    end

    context "Email sending" do
      context "ActionMailer" do
        let(:deliver) do
          ar_class.transaction do
            SampleEmail.hello.deliver_now
          end
        end

        let(:deliver_later) do
          ar_class.transaction do
            SampleEmail.hello.deliver_later
          end
        end

        let(:email_body) do
          ar_class.transaction do
            SampleEmail.hello.body
          end
        end

        context "when mailer adapter is disabled" do
          around do |ex|
            Isolator.adapters.mailer.disable!
            ex.run
            Isolator.adapters.mailer.enable!
          end

          it "doesn't raise" do
            expect { deliver }.to_not raise_error
          end
        end

        context "when mailer adapter is enabled" do
          around do |ex|
            Isolator.adapters.mailer.enable!
            ex.run
            Isolator.adapters.mailer.disable!
          end

          context "and active_job adapter is disabled" do
            around do |ex|
              Isolator.adapters.active_job.disable!
              ex.run
              Isolator.adapters.active_job.enable!
            end

            it "does not raise error on #deliver_later" do
              expect { deliver_later }.to_not raise_error
            end
          end

          it "raises Isolator::ActionMailerError on email delivering" do
            expect { deliver }.to raise_error(Isolator::MailerError)
          end

          it "does not raise error on email rendering" do
            expect { email_body }.to_not raise_error
          end
        end
      end

      context "Simple email" do
        around do |ex|
          Isolator.adapters.mailer.enable!
          ex.run
          Isolator.adapters.mailer.disable!
        end

        let(:send_email) do
          ar_class.transaction do
            Mail.deliver do
              to "me@me.com"
              from "you@you.com"
              subject "testing"
              body "hello"
            end
          end
        end

        it "raises Isolator::MailerError" do
          expect { send_email }.to raise_error(Isolator::MailerError)
        end
      end
    end
  end

  context "other transaction methods" do
    let(:connection) { ar_class.connection }
    subject(:make_request) { Net::HTTP.get("example.com", "/index.html") }

    describe "#execute" do
      specify do
        connection.execute("begin")
        expect { make_request }.to raise_error(Isolator::HTTPError)

        expect(Isolator).to be_within_transaction

        connection.execute("commit")
        expect(Isolator).to_not be_within_transaction
      end
    end

    describe "#begin_db_transaction" do
      specify do
        connection.begin_db_transaction
        expect { make_request }.to raise_error(Isolator::HTTPError)

        expect(Isolator).to be_within_transaction

        connection.commit_db_transaction
        expect(Isolator).to_not be_within_transaction
      end
    end
  end
end
