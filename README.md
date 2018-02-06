[![Gem Version](https://badge.fury.io/rb/isolator.svg)](https://badge.fury.io/rb/isolator)
[![Build Status](https://travis-ci.org/palkan/isolator.svg?branch=master)](https://travis-ci.org/palkan/isolator)

# Isolator

Detect non-atomic interactions within DB transactions.

Examples:

```ruby
# HTTP calls within transaction
User.transaction do
  user = User.new(user_params)
  user.save!
  # HTTP API call
  PaymentsService.charge!(user)
end

#=> raises Isolator::HTTPError

# background job
User.transaction do
  user.update!(confirmed_at: Time.now)
  UserMailer.successful_confirmation(user).deliver_later
end

#=> raises Isolator::BackgroundJobError
```

## Installation

Add this line to your application's Gemfile:

```ruby
group :development, :test do
  gem "isolator"
end
```

## Usage

TBD

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/isolator.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
