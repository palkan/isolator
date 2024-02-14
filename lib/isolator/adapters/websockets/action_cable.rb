# frozen_string_literal: true

Isolator.isolate :action_cable,
  target: ActionCable::Server::Base,
  method_name: :broadcast,
  exception_class: Isolator::WebsocketError,
  details_message: ->(_obj, args) {
    channel = args.first

    "Broadcasting to #{channel}"
  }
