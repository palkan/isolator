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

Of course, Isolator can detect _implicit_ transactions too. Consider this pretty common bad practice–enqueueing background job from `after_create` callback:

```ruby
class Comment < ApplicationRecord
  # the good way is to use after_create_commit
  # (or not use callbacks at all)
  after_create :notify_author

  private

  def notify_author
    CommentMailer.comment_created(self).deliver_later
  end
end

Comment.create(text: "Mars is watching you!")
#=> raises Isolator::BackgroundJobError
```

Isolator is supposed to be used in tests and on staging.

## Installation

Add this line to your application's Gemfile:

```ruby
# We suppose that Isolator is used in development and test
# environments.
group :development, :test do
  gem "isolator"
end

# Or you can add it to Gemfile with `require: false`
# and require it manually in your code.
#
# This approach is useful when you want to use it in staging env too.
gem "isolator", require: false
```

## Usage

Isolator is a plug-n-play tool, so, it begins to work right after required.

However, there are some potential caveats:

1) Isolator tries to detect the environment automatically and includes only necessary adapters. Thus the order of loading gems matters: make sure that `isolator` is required in the end (NOTE: in Rails, all adapters loaded after application initialization).

2) Isolator does not distinguish framework-level adapters. For example, `:active_job` spy doesn't take into account which AJ adapter you use; if you are using a safe one (e.g. `Que`) just disable the `:active_job` adapter to avoid false negatives (i.e. `Isolator.adapters.active_job.disable!`).

3) Isolator tries to detect the `test` environment and slightly change its behavior: first, it respect _transactional tests_; secondly, error raising is turned on by default (see [below](#configuration)).

### Configuration

```ruby
Isolator.configure do |config|
  # Specify a custom logger to log offenses
  config.logger = nil

  # Raise exception on offense
  config.raise_exceptions = false # true in test env

  # Send notifications to uniform_notifier
  config.send_notifications = false
end
```

Isolator relys on [uniform_notifier][] to send custom notifications.

**NOTE:** `uniform_notifier` should be installed separately (i.e., added to Gemfile).

### Supported ORMs

- `ActiveRecord` >= 4.1
- `ROM::SQL` (only if Active Support instrumentation extenstion is loaded)

### Adapters

Isolator has a bunch of built-in adapters:
- `:http` – built on top of [Sniffer][]
- `:active_job`
- `:sidekiq`
- `:action_mailer`

You can dynamically enable/disable adapters, e.g.:

```ruby
# Disable HTTP adapter == do not spy on HTTP requests
Isolator.adapters.http.disable!

# Enable back

Isolator.adapters.http.enable!
```

## Custom Adapters

An adapter is just a combination of a _method wrapper_ and lifecycle hooks.

Suppose that you have a class `Danger` with a method `#explode`, which is not safe to be run within a DB transaction. Then you can _isolate_ it (i.e., register with Isolator):

```ruby
# The first argument is a unique adapter id,
# you can use it later to enable/disable the adapter
#
# The second argument is the method owner and
# the third one is a method name.
Isolotar.isolate :danger, Danger, :explode, **options

# NOTE: if you want to isolate a class method, use signleton_class instead
Isolator.isolate :danger, Danger.singleton_class, :explode, **options
```

Possible `options` are:
- `exception_class` – an exception class to raise in case of offense
- `exception_message` – custom exception message (could be specified without a class)

You can also add some callbacks to be run before and after the transaction:

```ruby
Isolator.before_isolate do
 # right after we enter the transaction
end

Isolator.after_isolate do
 # right after the transaction has been committed/rollbacked
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/isolator.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[Sniffer]: https://github.com/aderyabin/sniffer
[uniform_notifier]: https://github.com/flyerhzm/uniform_notifier
