# frozen_string_literal: true

require_relative "./active_support_subscriber"
require_relative "./disconnection_handler"

Isolator::ActiveSupportSubscriber.subscribe!("sql.active_record")
Isolator::DisconnectionHandler.register_cleanup!