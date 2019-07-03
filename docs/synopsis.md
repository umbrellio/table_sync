# TableSync

Table synchronization via RabbitMQ

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

# Manual publishing

`TableSync::Publisher.new(object_class, original_attributes, confirm: true, state: :updated)` where
state is one of `:created / :updated / :destroyed` and `confirm` is Rabbit's confirm delivery flag

# Manual publishing with batches

You can use `TableSync::BatchPublisher` to publish changes in batches (array of hashes in `attributes`).
For now, only the following changes in the table can be published: `create` and` update`.

When using `TableSync::BatchPublisher`,` TableSync.routing_key_callable` is called as follows:
`TableSync.routing_key_callable.call(klass, {})`, i.e. empty hash is passed instead of attributes.
And `TableSync.routing_metadata_callable` is not called at all: header value is set to empty hash.

`TableSync::BatchPublisher.new(object_class, original_attributes_array, **options)`, where `original_attributes_array` is an array with hash of attributes of published objects and `options` is a hash of options.

`options` consists of:
- `confirm`, which is a flag for RabbitMQ, `true` by default
- `routing_key`, which is a custom key used (if given) to override one from `TableSync.routing_key_callable`, `nil` by default
- `push_original_attributes` (default value is `false`), if this option is set to `true`,
original_attributes_array will be pushed to Rabbit instead of fetching records from database and sending their mapped attributes.

Example:

```ruby
TableSync::BatchPublisher.new("SomeClass", [{ id: 1 }, { id: 2 }], confirm: false, routing_key: "custom_routing_key")
```

# Manual publishing with batches (Russian)

С помощью класса `TableSync::BatchPublisher` вы можете опубликовать изменения батчами (массивом в `attributes`).
Пока можно публиковать только следующие изменения в таблице: `создание записи` и `обновление записи`.

При использовании `TableSync::BatchPublisher`, `TableSync.routing_key_callable` вызывается следующим образом:
`TableSync.routing_key_callable.call(klass, {})`, то есть вместо аттрибутов передается пустой хэш.
А `TableSync.routing_metadata_callable` не вызывается вовсе: в хидерах устанавливается пустой хэш.

`TableSync::BatchPublisher.new(object_class, original_attributes_array, **options)`, где `original_attributes_array` - массив с аттрибутами публикуемых объектов и `options`- это хэш с дополнительными опциями.

`options` состоит из:
- `confirm`, флаг для RabbitMQ, по умолчанию - `true`
- `routing_key`, ключ, который (если указан) замещает ключ, получаемый из `TableSync.routing_key_callable`, по умолчанию - `nil`
- `push_original_attributes` (значение по умолчанию `false`), если для этой опции задано значение true, в Rabbit будут отправлены original_attributes_array, вместо получения значений записей из базы непосредственно перед отправкой.

Example:

```ruby
TableSync::BatchPublisher.new("SomeClass", [{ id: 1 }, { id: 2 }], confirm: false, routing_key: "custom_routing_key")
```

# Receiving changes

Naming convention for receiving handlers is `Rabbit::Handler::GROUP_ID::TableSync`,
where `GROUP_ID` represents first part of source exchange name.
Define handler class inherited from `TableSync::ReceivingHandler`
and named according to described convention.
You should use DSL inside the class.
Suppose we will synchronize models {Project, News, User} project {MainProject}, then:

```ruby
class Rabbit::Handler::MainProject::TableSync < TableSync::ReceivingHandler
  queue_as :custom_queue

  receive "Project", to_table: :projects

  receive "News", to_table: :news, events: :update do
    after_commit on: :update do
      NewsCache.reload
    end
  end

  receive "User", to_table: :clients, events: %i[update destroy] do
    mapping_overrides email: :project_user_email, id: :project_user_id

    only :project_user_email, :project_user_id
    target_keys :project_id, :project_user_id
    rest_key :project_user_rest
    version_key :project_user_version

    additional_data do |project_id:|
      { project_id: project_id }
    end

    default_values do
      { created_at: Time.current }
    end
  end

  receive "User", to_table: :users do
    rest_key nil
  end
end
```

### Handler class (`Rabbit::Handler::MainProject::TableSync`)

In this case:
- `TableSync` - RabbitMQ event type.
- `MainProject` - event source.
- `Rabbit::Handler` - module for our handlers of events from RabbitMQ (there might be others)

Method `queue_as` allow you to set custom queue.

### Recieving handler batch processing

Receiving handler supports array of attributes in a single update event. Corresponding
upsert-style logic in ActiveRecord and Sequel orm handlers is provided.

### Config DSL
```ruby
receive source, to_table:, [events:, &block]
```

The method receives following arguments
- `source` - string, name of source model (required)
- `to_table` - destination_table hash (required)
- `events` - array of supported events (optional)
- `block` - configuration block (optional)

This method implements logic of mapping `source` to `to_table` and allows customizing the event handling logic with provided block.
You can use one `source` for a lot of `to_table`.

The following options are available inside the block:
- `only` - whitelist for receiving attributes
- `skip` - return truthy value to skip the row
- `target_keys` - primary keys or unique keys
- `rest_key` - name of jsonb column for attributes which are not included in the whitelist. You can set the `rest_key(false)` or `rest_key(nil)` if you won't need the rest data.
- `version_key` - name of version column
- `first_sync_time_key` - name of the column where the time of first record synchronization should be stored. Disabled by default.
- `mapping_overrides` - map for overriding receiving columns
- `additional_data` - additional data for insert or update (e.g. `project_id`)
- `default_values` - values for insert if a row is not found
- `partitions` - proc that is used to obtain partitioned data to support table partitioning. Must return a hash which
 keys are names of partitions of partitioned table and values - arrays of attributes to be inserted into particular
 partition `{ measurements_2018_01: [ { attrs }, ... ], measurements_2018_02: [ { attrs }, ... ], ...}`.
 While the proc is called inside an upsert transaction it is suitable place for creating partitions for new data.
 Note that transaction of proc is a TableSynk.orm transaction.

```ruby
partitions do |data:|
  data.group_by { |d| "measurements_#{d[:time].year}_#{d[:time].month}" }
      .tap { |data| data.keys.each { |table| DB.run("CREATE TABLE IF NOT EXISTS #{table} PARTITION OF measurements") } }
end
```

Each of options can receive static value or code block which will be called for each event with the following arguments:
- `event` - type of event (`:update` or `:destroy`)
- `model` - source model (`Project`, `News`, `User` in example)
- `version` - version of the data
- `project_id` - id of project which is used in RabbitMQ
- `data` - raw data from event (before applying `mapping_overrides`, `only`, etc.)

Also, the `additional_data`, `skip` has a `current_row` field, which gives you a hash of all parameters of the current row (useful when receiving changes in batches).

Block can receive any number of parameters from the list.

### Callbacks
You can set callbacks like this:
```ruby
before_commit on: event, &block
after_commit on: event, &block
```
TableSync performs this callbacks after transaction commit as to avoid side effects. Block receives array of
record attributes.

### Notifications

The instrumentation API provided by Active Support.

Now available types of events:
`"tablesync.receive.update"`, `"tablesync.receive.destroy"`, `"tablesync.publish.update"` and `"tablesync.receive.destroy"`

 Also, you can subscribe with regexp like `/tablesync.receive/`.

 You have access to the payload, which contains `table`,  `event`, `direction` and `count`, for example:
```
{
  :table => "users",
  :event => :update,
  :direction => :publish,
  :count => 1
}
```

 See more about events at https://guides.rubyonrails.org/active_support_instrumentation.html
