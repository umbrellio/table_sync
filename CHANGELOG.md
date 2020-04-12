# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- Introduce Plugin ecosystem (**TableSync::Plugins**);

## [2.1.1] - 2020-04-10
### Fixed
- Updated docs for batch_publishing to fully reflect changes in 2.1.0

## [2.1.0] - 2020-04-09
### Added
- **TableSync::BatchPublisher**: custom headers;
- **TableSync::BatchPublisher**: custom events;

### Changed
- Slight changes to specs

## [2.0.0] - 2020-04-06
### Changed
- Sequel publishing hooks: checking for `:destroy` events inside `:if`/`:unless` predicates

## [1.13.1] - 2020-03-24
### Fixed
- **TableSync::BatchPublisher**: incorrect `attrs_for_metadata` definition (typo in method name);

## [1.13.0] - 2019-11-02
### Added
- Wrapping interface around receiving logic (`wrap_receiving`);

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
