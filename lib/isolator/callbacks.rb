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

    def start!
      before_isolate_callbacks.each(&:call)
    end

    def finish!
      after_isolate_callbacks.each(&:call)
    end

    def before_isolate_callbacks
      @before_isolate_callbacks ||= []
    end

    def after_isolate_callbacks
      @after_isolate_callbacks ||= []
    end
  end
end