# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Database subtransactions" do
  before do
    Isolator.config.max_subtransactions_depth = 1
  end

  it "allows transactions up to the limit" do
    expect {
      ActiveRecord::Base.transaction do
        User.create(name: "test")
        ActiveRecord::Base.transaction(requires_new: true) do
          User.create(name: "test")
        end
      end
    }.not_to raise_error
  end

  it "raises error when exceeding the limit" do
    expect {
      ActiveRecord::Base.transaction do
        User.create(name: "test")
        ActiveRecord::Base.transaction(requires_new: true) do
          User.create(name: "test")
          ActiveRecord::Base.transaction(requires_new: true) do
            User.create(name: "test")
          end
        end
      end
    }.to raise_error(Isolator::MaxSubtransactionsExceededError)
  end
end
