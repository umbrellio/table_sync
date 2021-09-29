# Publishing

TableSync can be used to send the data using RabbitMQ.

You can send the data in two ways. Automatic and manual.
Each one has its own pros and cons.

Automatic is used to publish changes in realtime, as soon as the tracked entity changes.
Usually syncs one entity at a time.

Manual allows to sync a lot of entities per message.
But demands greater amount of work and data preparation.

## Automatic

Include `TableSync.sync(self)` into a Sequel or ActiveRecord model. `:if` and `:unless` are supported for Sequel and ActiveRecord.

Functioning `Rails.cache` is required.

After some change happens, TableSync enqueues a job which then publishes a message.

Example:

```ruby
class SomeModel < Sequel::Model
  TableSync.sync(self, { if: -> (*) { some_code } })
end
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