# frozen_string_literal: true

require "open3"

module IntegrationHelpers
  def run_rspec(path, chdir: nil, env: {}, tag: nil)
    chdir ||= File.expand_path("../integrations/fixtures/rspec", __dir__)
    tagstr = tag.nil? ? "" : " --tag #{tag}"
    output, _status = Open3.capture2(
      env,
      "bundle exec rspec #{path}_fixture.rb#{tagstr}",
      chdir: chdir
    )
    output
  end

  def run_minitest(path, chdir: nil, env: {}, name: nil)
    (env["TESTOPTS"] ||= +"") << "--name #{name}"
    chdir ||= File.expand_path("../integrations/fixtures/minitest", __dir__)
    output, _status = Open3.capture2(
      env,
      "bundle exec ruby #{path}_fixture.rb #{env['TESTOPTS']}",
      chdir: chdir
    )
    output
  end
end
