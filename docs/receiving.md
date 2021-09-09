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
    after_commit_on_update do
      NewsCache.reload
    end
  end

  receive "User", to_table: :clients, events: %i[update destroy] do
    mapping_overrides email: :project_user_email, id: :project_user_id

    only :project_user_email, :project_user_id, :project_id
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

  receive "User", to_model: CustomModel.new(:users) do
    rest_key false
  end
end
```

### Handler class (`Rabbit::Handler::MainProject::TableSync`)

In this case:
- `TableSync` - RabbitMQ event type.
- `MainProject` - event source.
- `Rabbit::Handler` - module for our handlers of events from RabbitMQ (there might be others)

Method `queue_as` allows you to set custom queue.

### Recieving handler batch processing

Receiving handler supports array of attributes in a single update or destroy event. Corresponding
upsert-style logic in ActiveRecord and Sequel orm handlers are provided.

### Config
```ruby
receive source, [to_table:, to_model:, events:, &block]
```

The method receives following arguments
- `source` - string, name of source model (required)
- `to_table` - destination table name (required if not set to_model)
- `to_model` - destination model (required if not set to_table)
- `events` - array of supported events (optional)
- `block` - configuration block with options (optional)

This method implements logic of mapping `source` to `to_table` (or to `to_model`) and allows customizing
the event handling logic with provided block.
You can use one `source` for a lot of `to_table` or `to_moel`.

### Options:

Most of the options can be set as computed value or as a process.

```ruby
option(value)
```

```ruby
option do |key params|
  value
end
```

Each of options can receive static value or code block which will be called for each event with the following arguments:
- `event` - type of event (`:update` or `:destroy`)
- `model` - source model (`Project`, `News`, `User` in example)
- `version` - version of the data
- `project_id` - id of project which is used in RabbitMQ
- `raw_data` - raw data from event (before applying `mapping_overrides`, `only`, etc.)

Blocks can receive any number of parameters from the list.

All specific key params will be explained in examples for each option.

#### only
Whitelist for receiving attributes.

```ruby
only(instance of Array)
```

```ruby
only do |row:|
  return instance of Array
end
```

default value is taken through the call `model.columns`

#### target_keys
Primary keys or unique keys.

```ruby
target_keys(instance of Array)
```

```ruby
target_keys do |data:|
  return instance of Array
end
```

default value is taken through the call `model.primary_keys`

#### rest_key
Name of jsonb column for attributes which are not included in the whitelist.
You can set the `rest_key(false)` if you won't need the rest data.

```ruby
rest_key(instance of Symbol)
```

```ruby
rest_key do |row:, rest:|
  return instance of Symbol
end
```
default value is `:rest`

#### version_key
Name of version column.

```ruby
version_key(instance of Symbol)
```

```ruby
version_key do |data:|
  return instance of Symbol
end
```
default value is `:version`

#### except
Blacklist for receiving attributes.

```ruby
except(instance of Array)
```

```ruby
except do |row:|
  return instance of Array
end
```

default value is `[]`

#### mapping_overrides
Map for overriding receiving columns.

```ruby
mapping_overrides(instance of Hash)
```

```ruby
mapping_overrides do |row:|
  return instance of Hash
end
```

default value is `{}`

#### additional_data
Additional data for insert or update (e.g. `project_id`).

```ruby
additional_data(instance of Hash)
```

```ruby
additional_data do |row:|
  return instance of Hash
end
```

default value is `{}`

#### default_values
Values for insert if a row is not found.

```ruby
default_values(instance of Hash)
```

```ruby
default_values do |data:|
  return instance of Hash
end
```

default value is `{}`

#### skip
Return truthy value to skip the row.

```ruby
skip(instance of TrueClass or FalseClass)
```

```ruby
skip do |data:|
  return instance of TrueClass or FalseClass
end
```

default value is `false`

#### wrap_receiving
Proc that is used to wrap the receiving logic by custom block of code.

```ruby
wrap_receiving do |data:, target_keys:, version_key:, default_values: {}, event:, &receiving_logic|
  receiving_logic.call
  return makes no sense
end
```

event option is current fired event
default value is `proc { |&block| block.call }`

#### before_update
Perform code before updating data in the database.

```ruby
before_update do |data:, target_keys:, version_key:, default_values:|
  return makes no sense
end

before_update do |data:, target_keys:, version_key:, default_values:|
  return makes no sense
end
```

Сan be defined several times. Execution order guaranteed.

#### after_commit_on_update
Perform code after updated data was committed.

```ruby
after_commit_on_update do |data:, target_keys:, version_key:, default_values:, results:|
  return makes no sense
end

after_commit_on_update do |data:, target_keys:, version_key:, default_values:, results:|
  return makes no sense
end
```

- `results` - returned value from `model.upsert`

Сan be defined several times. Execution order guaranteed.

#### before_destroy
Perform code before destroying data in database.

```ruby
before_destroy do |data:, target_keys:, version_key:|
  return makes no sense
end

before_destroy do |data:, target_keys:, version_key:|
  return makes no sense
end
```

Сan be defined several times. Execution order guaranteed.

#### after_commit_on_destroy
Perform code after destroyed data was committed.

```ruby
after_commit_on_destroy do |data:, target_keys:, version_key:, results:|
  return makes no sense
end

after_commit_on_destroy do |data:, target_keys:, version_key:, results:|
  return makes no sense
end
```

- `results` - returned value from `model.destroy`

Сan be defined several times. Execution order guaranteed.

### Custom model
You can use custom model for receiving.
```
class Rabbit::Handler::MainProject::TableSync < TableSync::ReceivingHandler
  receive "Project", to_model: CustomModel.new
end
```

This model has to implement next interface:
```
def columns
  return all columns from table
end

def primary_keys
  return primary keys from table
end

def upsert(data: Array, target_keys: Array, version_key: Symbol, default_values: Hash)
  return array with updated rows
end

def destroy(data: Array, target_keys: Array, version_key: Symbol)
  return array with delited rows
end

def transaction(&block)
  block.call
  return makes no sense
end

def after_commit(&block)
  block.call
  return makes no sense
end
```
