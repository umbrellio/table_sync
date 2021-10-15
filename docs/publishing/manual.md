# Manual Sync

There are two ways you can manually publish large amounts of data.

### `TableSync::Publishing:Batch`

Easier to use, but does a lot of DB queries. May filter out invalid PK values.

#### Pros:

- requires less work
- it will automatically use methods for data customization (`#attributes_for_sync`, `#attributes_for_destroy`)
- you can be sure that data you publish is valid (more or less)
- serializes values for (`#publish_later`)

#### Cons:

- it queries database for each entity in batch (for `create` and `update`)
- it may also do a lot of queries if `#attributes_for_sync` contains additional data from other connected entities
- serializes values for (`#publish_later`); if your PK contains invalid values (ex. Date) they will be filtered out

### `TableSync::Publishing:Raw`

More complex to use, but requires very few DB queries.
You are responsible for the data you send!

#### Pros:

- very customizable; only requirement - `object_class` must exist
- you can send whatever data you want

#### Cons:

- you have to manually prepare data for publishing
- you have to be really sure you are sending valid data

## Tips

- **Don't make data batches too large!**

It may result in failure to process them. Good rule is to send approx. 5000 rows in one batch.

- **Make pauses between publishing data batches!**

Publishing without pause may overwhelm the receiving side. Either their background job processor (ex. Sidekiq) may clog with jobs, or their consumers may not be able to get messages from Rabbit server fast enough.

1 or 2 seconds is a good wait period.

- **Do not use `TableSync::Publishing:Single` to send millions or even thousands of rows of data.**

Or just calling update on rows with automatic sync.
It WILL overwhelm the receiving side. Especially if they have some additional receiving logic.

- **On the receiving side don't create job with custom logic (if it exists) for every row in a batch.**

Better to process it whole. Otherwise three batches of 5000 will result in 15000 new jobs.

- **Send one test batch before publishing the rest of the data.**

Make sure it was received properly. This way you won't send a lot invalid messages.

- **Check the other arguments.**

    - Ensure the routing_key is correct if you are using a custom one. Remember, that batch publishing ignores `#attributes_for_routing_key` on a model.
    - Ensure that `object_class` is correct. And it belongs to entities you want to send.
    - Ensure that you chose the correct event.
    - If you have some logic depending on headers, ensure they are also correct. Remember, that batch publishing ignores `#attributes_for_headers` on a model.

- **You can check what you send before publishing with:**

```ruby
TableSync::Publishing:Batch.new(...).message.message_params

TableSync::Publishing:Raw.new(...).message.message_params
```

## Examples

### `TableSync::Publishing:Raw`

```ruby
  # For Sequel
  # gem 'sequel-batches' or equivalent that will allow you to chunk data somehow
  # or #each_page from Sequel

  # this is a simple query
  # they can be much more complex, with joins and other things
  # just make sure that it results in a set of data you expect
  data = User.in_batches(of: 5000).naked.select(:id, :name, :email)

  data.each_with_index do |batch, i|
    TableSync::Publishing::Raw.new(
      object_class: "User",
      original_attributes: batch,
      event: :create,
      routing_key: :custom_key,   # optional
      headers: { type: "admin" }, # optional
    ).publish_now

    # make a pause between batches
    sleep 1

    # for when you are sending from terminal
    # allows you to keep an eye on progress
    # you can create more complex output
    puts "Batch #{i} sent!"
  end

```

#### Another way to gather data

If you don't want to create a data query (maybe it's too complex) but there is a lot of quereing in `#attributes_for_sync` and you are willing to trade a little bit of perfomance, you can try the following.

```ruby
class User < Sequel
  one_to_many :user_info

  # For example our receiving side wants to know the ips user logged in under
  # But doesn't want to sync the user_info
  def attributes_for_sync
    attributes.merge(
      ips: user_info.ips
    )
  end
end

# to prevent the need to query for every piece of additional data we can user eager load
# and construct published data by calling #attributes_for_sync
# don't forget to chunk it into more managable sizes before trying to send
data = User.eager(:statuses).map { |user| user.attributes_for_sync }
```
This way it will not make unnecessary queries.

### `TableSync::Publishing::Batch`

Remember, it will query or initialize each row.

```ruby
  # You can just send ids.
  data = User.in_batches(of: 5000).naked.select(:id)

  data.each_with_index do |data, i|
    TableSync::Publishing::Batch.new(
      object_class: "User",
      original_attributes: data,
      event: :create,
      routing_key: :custom_key,   # optional
      headers: { type: "admin" }, # optional
    ).publish_now

    sleep 1
    puts "Batch #{i} sent!"
  end
```
