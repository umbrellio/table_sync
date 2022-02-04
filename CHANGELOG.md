# Changelog
All notable changes to this project will be documented in this file.

## [6.0.4] - 2022-02-05
### Fixed

- `Debouncer` calculates proper `next_sync_time`

## [6.0.3] - 2021-12-09
### Fixed
Fixed bug when routing key is nil.

## [6.0.2] - 2021-12-01
### Fixed
- Fixed bug: skip publish when object is new and event is destroy for ActiveRecord

## [6.0.1] - 2021-11-30
### Fixed
- fixed docs

## [6.0.0] - 2021-10-15
### Added

- A lot of specs for all the refactoring.
- Docs
- 100% coverage

### Changed
- Heavy refactoring of Publisher and BatchPublisher.
All code is separated in different modules and classes.

1. Job callables are now called:
- single_publishing_job_class_callable
- batch_publishing_job_class_callable

2. Now there are three main classes for messaging:
- TableSync::Publishing::Single - sends one row with initialization
- TableSync::Publishing::Batch  - sends batch of rows with initialization
- TableSync::Publishing::Raw    - sends raw data without checks

Separate classes for publishing, object data, Rabbit params, debounce, serialization.

3. Jobs are not constrained by being ActiveJob anymore. Just need to have #perform_at method

4. Changed some method names towards consistency:
- attrs_for_routing_key -> attributes_for_routing_key
- attrs_for_metadata    -> attributes_for_headers

5. Moved TableSync setup into separate classes.

6. Changed ORMAdapters.

7. Destroyed objects are initialized.
Now custom attributes for destruction will be called on instances.
- Obj.table_sync_destroy_attributes() -> Obj#attributes_for_destroy

8. Event constants are now kept in one place.

### Removed

- Plugin Errors

## [5.1.0] - 2021-09-09

### Changed
- Provide current fired event to wrap receiver. You'll be able to get it with `wrap_receiving(event:, **rest) {}` as usual for `data, target_keys, version_key`
- Update rails dependencies with patch version

## [5.0.1] - 2021-04-06
### Fixed
- documentation

### Changed
- update gems

## [5.0.0] - 2021-03-04
### Fixed
- Fix `delete` events being broken when either `#attrs_for_routing_key` or `#attrs_for_metadata` was defined on a model.

### Changed
- Instead of original attributes (default raw model attributes), use published attributes (as defined by `#attributes_for_sync` or `.table_sync_destroy_attributes`) for `TableSync.routing_key_callable` and `TableSync.routing_metadata_callable`.
- Send all original attributes for `delete` events instead of just PK.

## [4.2.2] - 2020-11-20
### Fixed
- potential data corruption with batches

## [4.2.1] - 2020-11-20
### Fixed
- bug with sorting data in handler, it was bad idea to use `.hash` replaced to `.to_s`

## [4.2.0] - 2020-11-19
- No changes. Just stabilization release.

## [4.1.2] - 2020-11-19
### Fixed
- bug with sorting data in handler

## [4.1.1] - 2020-11-06
### Fixed
- dead locks in receiving module (see: `spec/receiving/handler_spec.rb#avoid dead locks`)

## [4.1.0] - 2020-11-02
### Changed
- move `TableSync::Instrument.notify` from models to the handler
- fire `TableSync::Instrument.notify` after commit insted of in transaction

## [4.0.0] - 2020-10-23
### Returned
- config inheritance

### Removed
- TableSync::Plugins

## [3.0.0] - 2020-09-05
### Added
- option `except`
- `to_model` in receive method
- TableSync::Utils::InterfaceChecker

### Changed
- .rubocop.yml
- documentation
- modules hierarchy (split receiving and publishing)
  `TableSync::Publisher` -> `TableSync::Publishing::Publisher`
  `TableSync::BatchPublisher` -> `TableSync::Publishing::BatchPublisher`
  `TableSync::ReceivingHandler` -> `TableSync::Receiving::Handler`
- made data batches processing as native
- implemented callbacks as options
- implemented `wrap_receiving` as option
- type checking in options
- `before_commit on: event, &block` -> `before_update(&block)` or `before_destroy(&block)`
- `after_commit on: event, &block` -> `after_commit_on_update(&block)` or `after_commit_on_destroy(&block)`
- changed parameters in some options:
  add `raw_data`
  `current_row` -> `row`
  ...
  see documents for details

### Removed
- TableSync::Config::CallbackRegistry
- TableSync::EventActions
- TableSync::EventActions::DataWrapper
- config option `on_destroy`
- config option `partitions`
- config option `first_sync_time_key`

## [2.3.0] - 2020-07-22
### Added
- ruby 2.7 in Travis
- Gemfile.lock

### Changed
- some fixes to get rid of warnings for ruby 2.7 (implicit conversion of hashes into kwargs will be dropped)
- TableSync.sync now explicitly expects klass and kwargs (it converts them into hash)
- TableSync::Instrument.notify now explicitly expects kwargs and delegates them further as kwargs

### Removed
- ruby 2.3, 2.4 from Travis

## [2.2.0] - 2020-04-12
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
