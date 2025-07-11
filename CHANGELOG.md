# Change log

## master

- Fix mid-transaction connection switch issue. ([@viralpraxis][])

## 1.1.1 (2025-03-12)

- Fix handling Rails 8 `enqueue_after_transaction_commit` logic. ([@palkan][])

## 1.1.0 (2024-08-12)

- Add support for `ActiveJob::Base.enqueue_after_transaction_commit`. ([@joshuay03][])

- Add `ignore_on: (obj) -> bool` option for adapters. ([@palkan][])

- Add ActionCable adapter. ([@arthurWD][])

## 1.0.1 (2023-12-01) ❄️

- Fix Rails 7.0 support. ([@palkan][])

## 1.0.0 (2023-11-30)

- Add ability to track concurrent transactions to with a thread (e.g., to multiple databases). ([@palkan][])

  This feature is disabled by default, opt-in via: `Isolator.config.disallow_per_thread_concurrent_transactions = true`.

- Add `Isolator.on_transaction_begin` and `Isolator.on_transaction_end` callbacks. ([@palkan][])

- Drop Ruby 2.6 and Rails 5 support. ([@palkan][])

## 0.11.0 (2023-09-27)

- Use Rails new `transaction.active_record` event if available to better handle edge cases. ([@palkan][])

- Fix logging non-UTF8 strings. ([@palkan][])

  Fixes [#66](https://github.com/palkan/isolator/issues/66)

## 0.10.0 (2023-08-15)

- Support multiple databases with DatabaseCleaner. ([@palkan][])

- Fix query having invalid characters. ([@tagirahmad][])

  Fixes [#43](https://github.com/palkan/isolator/issues/43).

## 0.9.0 (2023-05-18)

- Support keyword arguments to isolated method in Ruby 3.0. ([@Mange][])
- Raise an error when an ignore file does not parse to a hash. ([@bobbymcwho][])
- Log all filtered backtrace lines to the logger ([@bobbymcwho][])
- Add support for removing dynamic adapters. ([@Mange][])
- Allow aliases in .isolator_todo.yml and .isolator_ignore.yml ([@tomgi][])

## 0.8.0 (2021-12-29)

- Drop Ruby 2.5 support.

- Add .isolator_ignore.yml configuration file for Rails application.

## 0.7.0 (2020-09-25)

- Add debug mode. ([@palkan][])

Use `ISOLATOR_DEBUG=true` to turn on debug mode, which prints some useful information: when a transaction is tracked,
thresholds are changed, etc.

- Track transactions for different connections independently. ([@mquan][], [@palkan][])

This, for example, makes Isolator compatible with Rails multi-database apps.

- Allow custom ignorer usage. ([@iiwo][])

- `Isolator.load_ignore_config` is deprecated in favor of `Isolator::Ignorer.prepare`. ([@iiwo][])

## 0.6.2 (2020-03-20)

- Make Sniffer version requirement open-ended. ([@palkan][])

- **Support Ruby 2.5+** ([@palkan][])

## 0.6.1 (2019-09-06)

- Fix Sniffer integration. ([@palkan][])

  Fixes [#21](https://github.com/palkan/isolator/issues/21).

## 0.6.0 (2019-04-12) 🚀

- Add support for exceptions message details. ([@palkan][])

  Make it possible to provide more information about the cause of the failure
  (for example, job class and arguments for background jobs, URL for HTTP).

- Change backtrace filtering behaviour. ([@palkan][])

  The default behaviour is to take the top five lines.
  You can customize it via `Isolator.config.backtrace_filter`.

## 0.5.0 (2018-08-29)

- [PR [#19](https://github.com/palkan/isolator/pull/19)] Adding support for ruby version 2.2.2. ([@shivanshgaur][])

## 0.4.0 (2018-06-15)

- [PR [#13](https://github.com/palkan/isolator/pull/13)] Allow load ignored offences from YML file using `load_ignore_config`. ([@DmitryTsepelev][])

## 0.3.0 (2018-04-02)

- Add support for the [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) gem. ([@Envek][])

## 0.2.2 (2018-03-28)

-  [Fix [#14](https://github.com/palkan/isolator/issues/14)] Always use default value for threshold. ([@palkan][])

    Previously, in multi-threaded env the default value were missing (and led to `KeyError`).

## 0.2.1 (2018-02-24)

- [PR [#10](https://github.com/palkan/isolator/pull/10)] Add `sucker_punch` adapter. ([@alexshgov][])
- [PR [#9](https://github.com/palkan/isolator/pull/9)] Add `resque scheduler` background job adapter. ([@dsalahutdinov][])

## 0.2.0 (2018-02-22)

- [PR [#8](https://github.com/palkan/isolator/pull/8)] Add resque background job adapter. ([@dsalahutdinov][])

## 0.1.1 (2018-02-21)

- Update `sniffer` required mininum version. ([@palkan][])

## 0.1.0 (2018-02-19)

- Add `test_after_commit` patch. ([@palkan][])

- [PR [#7](https://github.com/palkan/isolator/pull/7)] Add WebMock adapter. ([@palkan][])

- Add `ignore_if` modifier to adapter. ([@palkan][])

- [PR [#5](https://github.com/palkan/isolator/pull/5)] Add `mail` adapter. ([@alexshgov][])

- Initial version. ([@palkan][], [@TheSmartnik][], [@alexshgov][])

[@palkan]: https://github.com/palkan
[@alexshgov]: https://github.com/alexshgov
[@TheSmartnik]: https://github.com/TheSmartnik
[@dsalahutdinov]: https://github.com/dsalahutdinov
[@Envek]: https://github.com/Envek
[@DmitryTsepelev]: https://github.com/DmitryTsepelev
[@shivanshgaur]: https://github.com/shivanshgaur
[@iiwo]: https://github.com/iiwo
[@mquan]: https://github.com/mquan
[@bobbymcwho]: https://github.com/bobbymcwho
[@Mange]: https://github.com/Mange
[@tomgi]: https://github.com/tomgi
[@tagirahmad]: https://github.com/tagirahmad
[@arthurWD]: https://github.com/arthurWD
[@joshuay03]: https://github.com/joshuay03
[@viralpraxis]: https://github.com/viralpraxis
