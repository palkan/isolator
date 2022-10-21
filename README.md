[![Cult Of Martians](http://cultofmartians.com/assets/badges/badge.svg)](http://cultofmartians.com/tasks/isolator.html)
[![Gem Version](https://badge.fury.io/rb/isolator.svg)](https://badge.fury.io/rb/isolator)
![Build](https://github.com/palkan/isolator/workflows/Build/badge.svg)

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

4) Experimental [multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html) has been added in v0.7.0. Please, let us know if you encounter any issues.

### Configuration

```ruby
Isolator.configure do |config|
  # Specify a custom logger to log offenses
  config.logger = nil

  # Raise exception on offense
  config.raise_exceptions = false # true in test env

  # Send notifications to uniform_notifier
  config.send_notifications = false

  # Customize backtrace filtering (provide a callable)
  # By default, just takes the top-5 lines
  config.backtrace_filter = ->(backtrace) { backtrace.take(5) }

  # Define a custom ignorer class (must implement .prepare)
  # uses a row number based list from the .isolator_todo.yml file
  config.ignorer = Isolator::Ignorer
end
```

Isolator relies on [uniform_notifier][] to send custom notifications.

**NOTE:** `uniform_notifier` should be installed separately (i.e., added to Gemfile).

### Transactional tests support

 - Rails' baked-in [use_transactional_tests](https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html#class-ActiveRecord::FixtureSet-label-Transactional+Tests)
 - [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) gem. Make sure that you require isolator _after_ database_cleaner.

### Supported ORMs

- `ActiveRecord` >= 5.1 (4.2 likely till works, but we do not test against it anymore)
- `ROM::SQL` (only if Active Support instrumentation extension is loaded)

### Adapters

Isolator has a bunch of built-in adapters:
- `:http` – built on top of [Sniffer][]
- `:active_job`
- `:sidekiq`
- `:resque`
- `:resque_scheduler`
- `:sucker_punch`
- `:mailer`
- `:webmock` – track mocked HTTP requests (unseen by Sniffer) in tests

You can dynamically enable/disable adapters, e.g.:

```ruby
# Disable HTTP adapter == do not spy on HTTP requests
Isolator.adapters.http.disable!

# Enable back

Isolator.adapters.http.enable!
```

### Fix Offenses

For the actions that should be executed only after successful transaction commit (which is mostly always so), you can try to use the `after_commit` callback from [after_commit_everywhere] gem (or use native AR callback in models if it's applicable).

### Ignore Offenses

Since Isolator adapter is just a wrapper over original code, it may lead to false positives when there is another library patching the same behaviour. In that case you might want to ignore some offenses.

Consider an example: we use Sidekiq along with [`sidekiq-postpone`](https://github.com/marshall-lee/sidekiq-postpone)–gem that patches `Sidekiq::Client#raw_push` and allows you to postpone jobs enqueueing (e.g. to enqueue everything when a transaction is commited–we don't want to raise exceptions in such situation).

To ignore offenses when `sidekiq-postpone` is active, you can add an ignore `proc`:

```ruby
Isolator.adapters.sidekiq.ignore_if { Thread.current[:sidekiq_postpone] }
```

You can add as many _ignores_ as you want, the offense is registered iff all of them return false.

### Using with legacy Rails codebases

If you already have a huge Rails project it can be tricky to turn Isolator on because you'll immediately get a lot of failed specs. If you want to fix detected issues one by one, you can list all of them in the special files `.isolator_todo.yml` and `.isolator_ignore.yml` in the following way:

```
sidekiq:
  - app/models/user.rb:20
  - app/models/sales/**/*.rb
```

All the exceptions raised in the listed lines will be ignored.

The `.isolator_todo.yml` file is intended to point to the code that should be fixed later, and `.isolator_ignore.yml` points to the code that for some reasons is not expected to be fixed. (See https://github.com/palkan/isolator/issues/40)

### Using with legacy Ruby codebases

If you are not using Rails, you'll have to load ignores from file manually, using `Isolator::Ignorer.prepare(path:)`, for instance `Isolator::Ignorer.prepare(path: "./config/.isolator_todo.yml")`

## Custom Adapters

An adapter is just a combination of a _method wrapper_ and lifecycle hooks.

Suppose that you have a class `Danger` with a method `#explode`, which is not safe to be run within a DB transaction. Then you can _isolate_ it (i.e., register with Isolator):

```ruby
# The first argument is a unique adapter id,
# you can use it later to enable/disable the adapter
#
# The second argument is the method owner and
# the third one is a method name.
Isolator.isolate :danger, Danger, :explode, options

# NOTE: if you want to isolate a class method, use singleton_class instead
Isolator.isolate :danger, Danger.singleton_class, :explode, options
```

Possible `options` are:
- `exception_class` – an exception class to raise in case of offense
- `exception_message` – custom exception message (could be specified without a class)
- `details_message` – a block to generate additional exception message information:

```ruby
Isolator.isolate :active_job,
  target: ActiveJob::Base,
  method_name: :enqueue,
  exception_class: Isolator::BackgroundJobError,
  details_message: ->(obj) {
    "#{obj.class.name}(#{obj.arguments})"
  }

Isolator.isolate :promoter,
  target: UserPromoter,
  method_name: :call,
  details_message: ->(obj_, args, kwargs) {
    # UserPromoter.call(user, role, by: nil)
    user, role = args
    by = kwargs[:by]
    "#{user.name} promoted to #{role} by #{by&.name || "system"})"
  }
```

Trying to register the same adapter name twice will raise an error. You can guard for it, or remove old adapters before in order to replace them.

```ruby
unless Isolator.has_adapter?(:promoter)
  Isolator.isolate(:promoter, *rest)
end
```

```ruby
# Handle code reloading
class Messager
end

Isolator.remove_adapter(:messager)
Isolator.isolate(:messager, target: Messager, *rest)
```

You can also add some callbacks to be run before and after the transaction:

```ruby
Isolator.before_isolate do
 # right after we enter the transaction
end

Isolator.after_isolate do
 # right after the transaction has been committed/rolled back
end
```

## Troubleshooting

### Verbose output

In most cases, turning on verbose output for Isolator helps to identify the issue. To do that, you can either specify `ISOLATOR_DEBUG=true` environment variable or set `Isolator.debug_enabled` manually.

### Tests failing after upgrading to Rails 6.0.3 while using [Combustion](https://github.com/pat/combustion)

The reason is that Rails started using a [separate connection pool for advisory locks](https://github.com/rails/rails/pull/38235) since 6.0.3. Since Combustion usually applies migrations for every test run, this pool becomse visible to [test fixtures](https://github.com/rails/rails/blob/b738f1930f3c82f51741ef7241c1fee691d7deb2/activerecord/lib/active_record/test_fixtures.rb#L123-L127), which resulted in 2 transactional commits tracked by Isolator, which only expects one. That leads to false negatives.

To fix this disable migrations advisory locks by adding `advisory_locks: false` to your database configuration in `(spec|test)/internal/config/database.yml`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/palkan/isolator.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[Sniffer]: https://github.com/aderyabin/sniffer
[uniform_notifier]: https://github.com/flyerhzm/uniform_notifier
[after_commit_everywhere]: https://github.com/Envek/after_commit_everywhere
