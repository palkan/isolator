source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in isolator.gemspec
gemspec

gem 'pry-byebug'
gem 'sqlite3'
gem 'activerecord', '>= 5.0'
gem 'activejob'

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end
