# frozen_string_literal: true

require "fakeredis"
Resque.redis = Redis.new
