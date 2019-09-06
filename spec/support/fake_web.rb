# frozen_string_literal: true

require "webrick"
require "logger"

module FakeWeb
  def self.server
    @server ||= WEBrick::HTTPServer.new(
      Port: 4567,
      Logger: Logger.new(IO::NULL),
      AccessLog: []
    ).tap do |server|
      server.mount_proc "/" do |_, res|
        res.status = 200
        res.body = "OK"
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Thread.new { FakeWeb.server.start }
  end
end
