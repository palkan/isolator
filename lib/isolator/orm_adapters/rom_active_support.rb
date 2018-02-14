# frozen_string_literal: true

require_relative "./active_support_subscriber"

Isolator::ActiveSupportSubscriber.subscribe!("sql.rom")
