source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in isolator.gemspec
gemspec

gem "pry-byebug"

gem "sqlite3", "~> 1.4.0"

local_gemfile = File.join(__dir__, "Gemfile.local")

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem "rails", "~> 6.0"
end

gem 'uniform_notifier', '~> 1.11'
