### Notifications

#### ActiveSupport adapter

You can use an already existing ActiveSupport adapter:
```ruby
  TableSync.notifier = TableSync::InstrumentAdapter::ActiveSupport
```

This instrumentation API is provided by Active Support. It allows to subscribe to notifications:

```ruby
ActiveSupport::Notifications.subscribe(/tablesync/) do |name, start, finish, id, payload|
  # do something
end
```

Types of events available:
`"tablesync.receive.update"`, `"tablesync.receive.destroy"`, `"tablesync.publish.update"`
and `"tablesync.publish.destroy"`.

You have access to the payload, which contains  `event`, `direction`, `table`, `schema` and `count`.

```
{
  :event => :update,       # one of update / destroy
  :direction => :publish,  # one of publish / receive
  :table => "users",
  :schema => "public",
  :count => 1
}
```

 See more at https://guides.rubyonrails.org/active_support_instrumentation.html


#### Custom adapters

You can also create a custom adapter. It is expected to respond to the following method:

```ruby
  def notify(table:, event:, direction:, count:)
    # processes data about table_sync event
  end
```
