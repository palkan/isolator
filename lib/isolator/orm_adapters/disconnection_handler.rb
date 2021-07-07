# frozen_string_literal: true

module Isolator
  class DisconnectionHandler
    def self.register_cleanup!
      # Add callback to clean up connection after db disconnection.
      connection_adapter_klasses = ActiveRecord::Base.connection_handler.connection_pools.map { |pool| pool.connection.class }.uniq
      connection_adapter_klasses.each do |connection_adapter_klass|
        connection_adapter_klass.set_callback :checkin, :after do |conn|
          Isolator.remove_connection!(conn.object_id) unless conn.active?
        end
      end
    end
  end
end
