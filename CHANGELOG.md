# Changelog
All notable changes to this project will be documented in this file.

## [1.12.1] - 2019-09-27
### Fixed
- The `default_values` option no longer overrides original values.

## [1.12.0] - 2019-09-20
### Changed
- Payload for existing ActiveSupport adapter contains both `table` and `schema` fields now.

## [1.11.0] - 2019-09-11
### Added
- Receiving: inconsistent events raises `TableSync::UnprovidedEventTargetKeysError`
  (events that include only some of the target keys (or none))

## [1.10.0] - 2019-08-28
### Added
- convert symbolic values to strings in hashes to support older versions of activejob

## [1.9.0] - 2019-07-23
### Added
- add notifications

## [1.8.0] - 2019-07-23
### Added
- `debounce_time` option for publishing

## [1.7.0] - 2019-07-11
### Added
- `on_destroy` return value for manipulation with `after_commit` callback;

## [1.6.0] - 2019-07-08
### Added
- `on_destroy` - defines a custom logic and behavior for `destroy` event;
