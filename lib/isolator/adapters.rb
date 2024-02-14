# frozen_string_literal: true

require "isolator/adapters/http"
require "isolator/adapters/background_jobs"
require "isolator/adapters/mailers"
require "isolator/adapters/websockets"
require "isolator/adapters/after_commit" if defined?(::TestAfterCommit)
