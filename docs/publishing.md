# Publishing changes

Include `TableSync.sync(self)` into a Sequel or ActiveRecord model. `:if` and `:unless` are
supported for Sequel and ActiveRecord

Functioning `Rails.cache` is required

Example:

```ruby
class SomeModel < Sequel::Model
    TableSync.sync(self, { if: -> (*) { some_code } })
end
```

#### #attributes_for_sync

Models can implement `#attributes_for_sync` to override which attributes are published. If not
present, all attributes are published

#### #attrs_for_routing_key

Models can implement `#attrs_for_routing_key` to override which attributes are given to routing_key_callable. If not present, default attributes are given

#### #attrs_for_metadata

Models can implement `#attrs_for_metadata` to override which attributes are given to metadata_callable. If not present, default attributes are given

#### .table_sync_model_name

Models can implement `.table_sync_model_name` class method to override the model name used for
publishing events. Default is model class name

#### .table_sync_destroy_attributes(original_attributes)

Models can implement `.table_sync_destroy_attributes` class method to override the attributes
used for publishing destroy events. Default is object's primary key

## Configuration

- `TableSync.publishing_job_class_callable` is a callable which should resolve to a ActiveJob
subclass that calls TableSync back to actually publish changes (required)

Example:

```ruby
class TableSync::Job < ActiveJob::Base
  def perform(*args)
    TableSync::Publisher.new(*args).publish_now
  end
end
```

- `TableSync.batch_publishing_job_class_callable` is a callable which should resolve to a ActiveJob
subclass that calls TableSync batch publisher back to actually publish changes (required for batch publisher)

- `TableSync.routing_key_callable` is a callable which resolves which routing key to use when
publishing changes. It receives object class and attributes (required)

Example:

```ruby
TableSync.routing_key_callable = -> (klass, attributes) { klass.gsub('::', '_').tableize }
```

- `TableSync.routing_metadata_callable` is a callable that adds RabbitMQ headers which can be
used in routing (optional). One possible way of using it is defining a headers exchange and
routing rules based on key-value pairs (which correspond to sent headers)

Example:

```ruby
TableSync.routing_metadata_callable = -> (klass, attributes) { attributes.slice("project_id") }
```

- `TableSync.exchange_name` defines the exchange name used for publishing (optional, falls back
to default Rabbit gem configuration).

- `TableSync.notifier` is a module that provides publish and recieve notifications.

# Manual publishing

`TableSync::Publisher.new(object_class, original_attributes, confirm: true, state: :updated, debounce_time: 45)`
where state is one of `:created / :updated / :destroyed` and `confirm` is Rabbit's confirm delivery flag and optional param `debounce_time` determines debounce time in seconds, 1 minute by default.

# Manual publishing with batches

You can use `TableSync::BatchPublisher` to publish changes in batches (array of hashes in `attributes`).

When using `TableSync::BatchPublisher`,` TableSync.routing_key_callable` is called as follows:
`TableSync.routing_key_callable.call(klass, {})`, i.e. empty hash is passed instead of attributes.
And `TableSync.routing_metadata_callable` is not called at all: metadata is set to empty hash.

`TableSync::BatchPublisher.new(object_class, original_attributes_array, **options)`, where `original_attributes_array` is an array with hash of attributes of published objects and `options` is a hash of options.

`options` consists of:
- `confirm`, which is a flag for RabbitMQ, `true` by default
- `routing_key`, which is a custom key used (if given) to override one from `TableSync.routing_key_callable`, `nil` by default
- `push_original_attributes` (default value is `false`), if this option is set to `true`,
original_attributes_array will be pushed to Rabbit instead of fetching records from database and sending their mapped attributes.
- `headers`, which is an option for custom headers (can be used for headers exchanges routes), `nil` by default
- `event`, which is an option for event specification (`:destroy` or `:update`), `:update` by default

Example:

```ruby
TableSync::BatchPublisher.new(
  "SomeClass",
  [{ id: 1 }, { id: 2 }],
  confirm: false,
  routing_key: "custom_routing_key",
  push_original_attributes: true,
  headers: { key: :value },
  event: :destroy,
)
```

# Manual publishing with batches (Russian)

С помощью класса `TableSync::BatchPublisher` вы можете опубликовать изменения батчами (массивом в `attributes`).

При использовании `TableSync::BatchPublisher`, `TableSync.routing_key_callable` вызывается следующим образом:
`TableSync.routing_key_callable.call(klass, {})`, то есть вместо аттрибутов передается пустой хэш.
А `TableSync.routing_metadata_callable` не вызывается вовсе: в метадате устанавливается пустой хэш.

`TableSync::BatchPublisher.new(object_class, original_attributes_array, **options)`, где `original_attributes_array` - массив с аттрибутами публикуемых объектов и `options`- это хэш с дополнительными опциями.

`options` состоит из:
- `confirm`, флаг для RabbitMQ, по умолчанию - `true`
- `routing_key`, ключ, который (если указан) замещает ключ, получаемый из `TableSync.routing_key_callable`, по умолчанию - `nil`
- `push_original_attributes` (значение по умолчанию `false`), если для этой опции задано значение true, в Rabbit будут отправлены original_attributes_array, вместо получения значений записей из базы непосредственно перед отправкой.
- `headers`, опция для задания headers (можно использовать для задания маршрутов в headers exchange'ах), `nil` по умолчанию
- `event`, опция для указания типа события (`:destroy` или `:update`), `:update` по умолчанию

Example:

```ruby
TableSync::BatchPublisher.new(
  "SomeClass",
  [{ id: 1 }, { id: 2 }],
  confirm: false,
  routing_key: "custom_routing_key",
  push_original_attributes: true,
  headers: { key: :value },
  event: :destroy,
)
```