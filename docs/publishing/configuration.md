# Configuration

Customization, configuration and other options.

## Model Customization

There are methods you can define on a synched model to customize published messages for it.

### `#attributes_for_sync`

Models can implement `#attributes_for_sync` to override which attributes are published for `update` and `create` events. If not present, all attributes are published.

### `#attributes_for_destroy`

Models can implement `#attributes_for_destroy` to override which attributes are published for `destroy` events. If not present, `needle` (primary key) is published.

### `#attributes_for_routing_key`

Models can implement `#attributes_for_routing_key` to override which attributes are given to the `routing_key_callable`. If not present, published attributes are given.

### `#attributes_for_headers`

Models can implement `#attributes_for_headers` to override which attributes are given to the `headers_callable`. If not present, published attributes are given.

### `.table_sync_model_name`

Models can implement `.table_sync_model_name` class method to override the model name used for publishing events. Default is a model class name.

## Callables

Callables are defined once. TableSync will use them to dynamically resolve things like jobs, routing_key and headers.

### Single publishing job (required for automatic and delayed publishing)

- `TableSync.single_publishing_job_class_callable` is a callable which should resolve to a class that calls TableSync back to actually publish changes.

It is expected to have `.perform_at(hash_with_options)` and it will be passed a hash with the following keys:

- `original_attributes` - serialized `original_attributes`
- `object_class` - model name
- `debounce_time` - pause between publishing messages
- `event` - type of event that happened to synched entity
- `perform_at` - time to perform the job at (depends on debounce)

Example:

```ruby
TableSync.single_publishing_job_class_callable = -> { TableSync::Job }

class TableSync::Job < ActiveJob::Base
  def perform(jsoned_attributes)
    TableSync::Publishing::Single.new(
      JSON.parse(jsoned_attributes),
    ).publish_now
  end

  def self.perform_at(attributes)
    set(wait_until: attributes.delete(:perform_at))
      .perform_later(attributes.to_json)
  end
end

# will enqueue the job described above

TableSync::Publishing::Single.new(
  object_class: "User",
  original_attributes: { id: 1, name: "Mark" }, # will be serialized!
  debounce_time: 60,
  event: :update,
).publish_later
```

### Batch publishing job (required only for `TableSync::Publishing::Batch#publish_later`)

- `TableSync.batch_publishing_job_class_callable` is a callable which should resolve to a class that calls TableSync back to actually publish changes.

It is expected to have `.perform_later(hash_with_options)` and it will be passed a hash with the following keys:

- `original_attributes` - array of serialized `original_attributes`
- `object_class` - model name
- `event` - type of event that happened to synched entity
- `routing_key` - custom routing_key (optional)
- `headers` - custom headers (optional)

More often than not this job is not very useful, since it makes more sense to use `#publish_now` from an already existing job that does a lot of things (not just publishing messages).

### Example

```ruby
TableSync.batch_publishing_job_class_callable = -> { TableSync::BatchJob }

class TableSync::BatchJob < ActiveJob::Base
  def perform(jsoned_attributes)
    TableSync::Publishing::Batch.new(
      JSON.parse(jsoned_attributes),
    ).publish_now
  end

  def self.perform_later(attributes)
    super(attributes.to_json)
  end
end

TableSync::Publishing::Batch.new(
  object_class: "User",
  original_attributes: [{ id: 1, name: "Mark" }, { id: 2, name: "Bob" }], # will be serialized!
  event: :create,
  routing_key: :custom_key,   # optional
  headers: { type: "admin" }, # optional
).publish_later
```

### Routing key callable (required)

- `TableSync.routing_key_callable` is a callable that resolves which routing key to use when publishing changes. It receives object class and published attributes or `#attributes_for_routing_key` (if defined).

Example:

```ruby
TableSync.routing_key_callable = -> (klass, attributes) { klass.gsub('::', '_').tableize }
```

### Headers callable (required)

- `TableSync.headers_callable` is a callable that adds RabbitMQ headers which can be used in routing. It receives object class and published attributes or `#attributes_for_headers` (if defined).

One possible way of using it is defining a headers exchange and routing rules based on key-value pairs (which correspond to sent headers).

Example:

```ruby
TableSync.headers_callable = -> (klass, attributes) { attributes.slice("project_id") }
```

## Other

- `TableSync.exchange_name` defines the exchange name used for publishing (optional, falls back to default Rabbit gem configuration).

- `TableSync.notifier` is a module that provides publish and recieve notifications.

- `TableSync.raise_on_empty_message` - raises an error on empty message if set to true.

- `TableSync.orm` - set ORM (ActiveRecord or Sequel) used to process given entities. Required!
