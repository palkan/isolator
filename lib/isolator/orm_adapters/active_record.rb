# frozen_string_literal: true

require_relative "./active_support_subscriber"

# We rely on this feature introduced in 7.1.0.beta1: https://github.com/rails/rails/pull/49192
if ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1
  require_relative "./active_support_transaction_subscriber"
  Isolator::ActiveSupportTransactionSubscriber.subscribe!
else
  Isolator::ActiveSupportSubscriber.subscribe!("sql.active_record")
end
