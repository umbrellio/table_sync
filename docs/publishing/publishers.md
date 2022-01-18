# Publishers

There are three publishers you can use to send data.

- `TableSync::Publishing::Single` - sends one row with initialization.
- `TableSync::Publishing::Batch` - sends a batch of rows with initialization.
- `TableSync::Publishing::Raw`  - sends raw data without checks.

## Single

`TableSync::Publishing::Single` - sends one row with initialization.

This is a publisher called by `TableSync.sync(self)`.

### Expected parameters:

- `object_class` - class (model) used to initialize published object
- `original_attributes` - attributes used to initialize `object_class` with
- `debounce_time` - minimum allowed time between delayed publishings
- `event` - type of event that happened to the published object (`create`, `update`, `destroy`); `update` by default

### What it does (when uses `#publish_now`):
- takes in the `original_attributes`, `object_class`, `event`
- constantizes `object_class`
- extracts the primary key (`needle`) of the `object_class` from the `original_attributes`
- queries the database for the object with the `needle` (for `update` and `create`) or initializes the `object_class` with `original_attributes` (for `destroy`)
- constructs routing_key using `routing_key_callable` and `#attributes_for_routing_key` (if defined)
- constructs headers using `headers_callable` and `#attributes_for_headers` (if defined)
- publishes Rabbit message (uses attributes from queried/initialized object as data)
- sends notification (if set up)

### What it does (when uses `#publish_later`):
- takes in the `original_attributes`, `object_class`, `debounce_time`, `event`
- serializes the `original_attributes`, silently filters out unserializable keys/values
- enqueues (or skips) the job with the `serialized_original_attributes` to be performed in time according to debounce
- job (if enqueued) calls `TableSync::Publishing::Single#publish_now` with `serialized_original_attributes` and the same `object_class`, `debounce_time`, `event`

### Serialization

Currently allowed key/values are:
  `NilClass`, `String`, `TrueClass`, `FalseClass`, `Numeric`, `Symbol`.

### Job

Job is defined in `TableSync.single_publishing_job_class_callable` as a proc. Read more in [Configuration](docs/publishing/configuration.md).

### Example #1 (send right now)

```ruby
  TableSync::Publishing::Single.new(
    object_class: "User",
    original_attributes: { id: 1, name: "Mark" },
    debounce_time: 60, # useless for #publish _now, can be skipped
    event: :create,
  ).publish_now
```

### Example #2 (enqueue job)

```ruby
  TableSync::Publishing::Single.new(
    object_class: "User",
    original_attributes: { id: 1, name: "Mark" }, # will be serialized!
    debounce_time: 60,
    event: :update,
  ).publish_later
```

## Batch

- `TableSync::Publishing::Batch` - sends a batch of rows with initialization.

### Expected parameters:

- `object_class` - class (model) used to initialize published objects
- `original_attributes` - array of attributes used to initialize `object_class` with
- `event` - type of event that happened to the published objects (`create`, `update`, `destroy`); `update` by default
- `routing_key` - custom routing_key
- `headers` - custom headers

### What it does (when uses `#publish_now`):
- takes in the `original_attributes`, `object_class`, `event`, `routing_key`, `headers`
- constantizes `object_class`
- extracts primary keys (`needles`) of the `object_class` from the array of `original_attributes`
- queries the database for the objects with `needles` (for `update` and `create`) or initializes the `object_class` with `original_attributes` (for `destroy`)
- constructs routing_key using `routing_key_callable` (ignores `#attributes_for_routing_key`) or uses `routing_key` if given
- constructs headers using `headers_callable` (ignores `#attributes_for_headers`)  or uses `headers` if given
- publishes Rabbit message (uses attributes from queried/initialized objects as data)
- sends notification (if set up)

### What it does (when uses `#publish_later`):
- takes in the `original_attributes`, `object_class`, `event`, `routing_key`, `headers`
- serializes the array of `original_attributes`, silently filters out unserializable keys/values
- enqueues the job with the `serialized_original_attributes`
- job calls `TableSync::Publishing::Batch#publish_now` with `serialized_original_attributes` and the same `object_class`, `event`, `routing_key`, `headers`

### Serialization

Currently allowed key/values are:
  `NilClass`, `String`, `TrueClass`, `FalseClass`, `Numeric`, `Symbol`.

### Job

Job is defined in `TableSync.batch_publishing_job_class_callable` as a proc. Read more in [Configuration](docs/publishing/configuration.md).

### Example #1 (send right now)

```ruby
  TableSync::Publishing::Batch.new(
    object_class: "User",
    original_attributes: [{ id: 1, name: "Mark" }, { id: 2, name: "Bob" }],
    event: :create,
    routing_key: :custom_key,   # optional
    headers: { type: "admin" }, # optional
  ).publish_now
```

### Example #2 (enqueue job)

```ruby
  TableSync::Publishing::Batch.new(
    object_class: "User",
    original_attributes: [{ id: 1, name: "Mark" }, { id: 2, name: "Bob" }],
    event: :create,
    routing_key: :custom_key,   # optional
    headers: { type: "admin" }, # optional
  ).publish_later
```

## Raw
- `TableSync::Publishing::Raw` - sends raw data without checks.

Be carefull with this publisher. There are no checks for the data sent.
You can send anything.

### Expected parameters:

- `object_class` - model
- `model_name` - name of model, which will be insterted to the message payload. If `nil`,
`object_class` will be used instead
- `original_attributes` - raw data that will be sent
- `event` - type of event that happened to the published objects (`create`, `update`, `destroy`); `update` by default
- `routing_key` - custom routing_key
- `headers` - custom headers

### What it does (when uses `#publish_now`):
- takes in the `original_attributes`, `object_class`, `event`, `routing_key`, `headers`
- constantizes `object_class`
- constructs routing_key using `routing_key_callable` (ignores `#attributes_for_routing_key`) or uses `routing_key` if given
- constructs headers using `headers_callable` (ignores `#attributes_for_headers`)  or uses `headers` if given
- publishes Rabbit message (uses `original_attributes` as is)
- sends notification (if set up)

### Example

```ruby
  TableSync::Publishing::Raw.new(
    object_class: "User",
    original_attributes: [{ id: 1, name: "Mark" }, { id: 2, name: "Bob" }],
    event: :create,
    routing_key: :custom_key,   # optional
    headers: { type: "admin" }, # optional
  ).publish_now
```
