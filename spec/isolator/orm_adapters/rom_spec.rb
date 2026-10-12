# frozen_string_literal: true

require "spec_helper"

describe "ROM integration" do
  before { stub_const("ROM::SQL::ActiveSupportInstrumentation", Module.new) }

  after { ActiveSupport::Notifications.unsubscribe("sql.rom") }

  it "tracks transactions from sql.rom events" do
    load "isolator/orm_adapters.rb"

    ActiveSupport::Notifications.instrument("sql.rom", sql: "BEGIN")
    expect(Isolator).to be_within_transaction

    ActiveSupport::Notifications.instrument("sql.rom", sql: "COMMIT")
    expect(Isolator).not_to be_within_transaction
  end
end
