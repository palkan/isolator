# frozen_string_literal: true

source "https://rubygems.org"

gem "debug", platform: :mri

gemspec

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = "#{File.dirname(__FILE__)}/#{ENV.fetch("LOCAL_GEMFILE", "Gemfile.local")}"

if File.exist?(local_gemfile)
  eval_gemfile local_gemfile
else
  gem "rails", "~> 8.0"
  gem "sqlite3", "~> 2.0"
end
