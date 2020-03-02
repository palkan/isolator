# Change log

## master

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
