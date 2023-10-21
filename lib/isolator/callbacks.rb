# frozen_string_literal: true

module Isolator
  # Add before_isolate and after_isolate callbacks
  module Callbacks
    def before_isolate(&block)
      before_isolate_callbacks << block
    end

    def after_isolate(&block)
      after_isolate_callbacks << block
    end

    def on_transaction_begin(&block)
      transaction_begin_callbacks << block
    end

    def on_transaction_end(&block)
      transaction_end_callbacks << block
    end

    def start!
      return if Isolator.disabled?
      before_isolate_callbacks.each(&:call)
    end

    def finish!
      return if Isolator.disabled?
      after_isolate_callbacks.each(&:call)
    end

    def notify!(event, payload)
      if event == :begin
        transaction_begin_callbacks.each { |cb| cb.call(payload) }
      elsif event == :end
        transaction_end_callbacks.each { |cb| cb.call(payload) }
      end
    end

    def before_isolate_callbacks
      @before_isolate_callbacks ||= []
    end

    def after_isolate_callbacks
      @after_isolate_callbacks ||= []
    end

    def transaction_begin_callbacks
      @transaction_begin_callbacks ||= []
    end

    def transaction_end_callbacks
      @transaction_end_callbacks ||= []
    end
  end
end
