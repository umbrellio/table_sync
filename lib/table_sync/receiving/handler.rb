# frozen_string_literal: true

class TableSync::Receiving::Handler < Rabbit::EventHandler
  extend TableSync::Receiving::DSL

  # Rabbit::EventHandler uses Tainbox and performs `handler.new(message).call`
  attribute :event
  attribute :model
  attribute :version

  def call
    configs.each do |config|
      next unless config.allow_event?(event)

      data = processed_data(config)

      next if data.empty?

      version_key = config.version_key(data: data)
      data.each { |row| row[version_key] = version }

      target_keys = config.target_keys(data: data)

      validate_data(data, target_keys: target_keys)

      data.sort_by! { |row| row.values_at(*target_keys).map { |value| sort_key(value) } }

      params = { data: data, target_keys: target_keys, version_key: version_key }

      if event == :update
        params[:default_values] = config.default_values(data: data)
      end

      config.wrap_receiving(event: event, **params) do
        perform(config, params)
      end
    end
  end

  private

  # redefine setter from Rabbit::EventHandler
  def data=(data)
    super(Array.wrap(data[:attributes]))
  end

  def event=(event_name)
    event_name = event_name.to_sym

    if event_name.in?(TableSync::Event::VALID_RESOLVED_EVENTS)
      super(event_name)
    else
      raise TableSync::UndefinedEvent.new(event)
    end
  end

  def model=(model_name)
    super(model_name.to_s)
  end

  def configs
    @configs ||= begin
      configs = self.class.configs[model]
      configs = configs.sort_by { |config| "#{config.model.schema}.#{config.model.table}" }
      configs.map do |config|
        ::TableSync::Receiving::ConfigDecorator.new(
          config: config,
          # next parameters will be send to each proc-options from config
          event: event,
          model: model,
          version: version,
          project_id: project_id,
          raw_data: data,
        )
      end
    end
  end

  def processed_data(config)
    data.filter_map do |row|
      next if config.skip(row: row)

      row = row.dup

      config.mapping_overrides(row: row).each do |before, after|
        row[after] = row.delete(before)
      end

      config.except(row: row).each { |x| row.delete(x) }

      row.merge!(config.additional_data(row: row))

      only = config.only(row: row)
      row, rest = row.partition { |key, _| key.in?(only) }.map(&:to_h)

      rest_key = config.rest_key(row: row, rest: rest)
      (row[rest_key] ||= {}).merge!(rest) if rest_key

      row
    end
  end

  def validate_data(data, target_keys:)
    data.each do |row|
      next if target_keys.all? { |x| row.key?(x) }

      raise TableSync::DataError.new(
        data, target_keys, "Some target keys not found in received attributes!"
      )
    end

    if data.uniq { |row| row.slice(*target_keys) }.size != data.size
      raise TableSync::DataError.new(data, target_keys, "Duplicate rows found!")
    end

    keys_sample = data[0].keys
    keys_diff = data.each_with_object(Set.new) do |row, set|
      ((row.keys - keys_sample) | (keys_sample - row.keys)).each { |x| set.add(x) }
    end

    unless keys_diff.empty?
      raise TableSync::DataError.new(data, target_keys, <<~MESSAGE)
        Bad batch structure, check keys: #{keys_diff.to_a}
      MESSAGE
    end
  end

  def perform(config, params)
    model = config.model

    model.transaction do
      results = if event == :update
                  config.before_update(**params)
                  model.upsert(**params)
                else
                  config.before_destroy(**params)
                  model.destroy(**params)
                end

      model.after_commit do
        TableSync::Instrument.notify table: model.table, schema: model.schema,
                                     count: results.count, event: event, direction: :receive
      end

      if event == :update
        model.after_commit { config.after_commit_on_update(**params.merge(results: results)) }
      else
        model.after_commit { config.after_commit_on_destroy(**params.merge(results: results)) }
      end
    end
  end

  def sort_key(value)
    # value.respond_to?(:>) ? value : value.to_s
    value
  end
end
