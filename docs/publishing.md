# Publishing

TableSync can be used to send data using RabbitMQ.

You can do in two ways. Automatic and manual.
Each one has its own pros and cons.

Automatic is used to publish changes in realtime, as soon as the tracked entity changes.
Usually syncs one entity at a time.

Manual allows to sync a lot of entities per message.
But demands greater amount of work and data preparation.

## Automatic

Include `TableSync.sync(self)` into a Sequel or ActiveRecord model. 

Options:

- `if:` and `unless:` - Runs given proc in the scope of an instance. Skips sync on `false` for `if:` and on `true` for `unless:`.
- `on:` - specify events (`create`, `update`, `destroy`) to trigger sync on. Triggered for all of them without this option.
- `debounce_time` - min time period allowed between synchronizations.

Functioning `Rails.cache` is required.

How it works:

- `TableSync.sync(self)` - registers new callbacks (for `create`, `update`, `destroy`) for ActiveRecord model, and defines `after_create`, `after_update` and `after_destroy` callback methods for Sequel model.

- Callbacks call `TableSync::Publishing::Single#publish_later` with given options and object attributes. It enqueues a job which then publishes a message.

Example:

```ruby
class SomeModel < Sequel::Model
  TableSync.sync(self, { if: -> (*) { some_code }, unless: -> (*) { some_code }, on: [:create, :update] })
end

class SomeOtherModel < Sequel::Model
  TableSync.sync(self)
end
```

ActiveRecord features:

- Skip publish when object is new and event is destroy. 

Example: 

```ruby
  user = User.new.destroy!
  # `TableSync::Publishing::Single` isn't creating and message isn't sending to rabbit 
```



## Manual

Directly call one of the publishers. It's the best if you need to sync a lot of data.
This way you don't even need for the changes to occur.

Example:

```ruby
  TableSync::Publishing::Batch.new(
    object_class: "User",
    original_attributes: [{ id: 1 }, { id: 2 }],
    event: :update,
  ).publish_now
```

## Read More

- [Publishers](publishing/publishers.md)
- [Configuration](publishing/configuration.md)
- [Manual Sync (examples)](publishing/manual.md)
