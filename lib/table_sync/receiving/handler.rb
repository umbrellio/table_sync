# frozen_string_literal: true

class TableSync::Receiving::Handler < Rabbit::EventHandler
  extend TableSync::Receiving::DSL

  attr_accessor :version
  attr_reader :event, :model

  def initialize(message)
    super

    self.event   = message.data[:event]
    self.model   = message.data[:model]
    self.version = message.data[:version]
  end

  def call
    configs.each do |config|
      next unless config.allow_event?(event)

      data = processed_data(config)

      next if data.empty?

      target_keys = config.option(:target_keys, data:)

      validate_data(data, target_keys:)

      data.sort_by! { |row| row.values_at(*target_keys).map { |value| sort_key(value) } }

      version_key = config.option(:version_key, data:)
      params = { data:, target_keys:, version_key: }

      if event == :update
        params[:default_values] = config.option(:default_values, data:)
      end

      config.option(:wrap_receiving, **params) do
        perform(config, params)
      end
    end
  end

  private

  # redefine setter from Rabbit::EventHandler
  def data=(raw_data)
    super(Array.wrap(raw_data[:attributes]))
  end

  def event=(event_name)
    event_name = event_name.to_sym

    if event_name.in?(TableSync::Event::VALID_RESOLVED_EVENTS)
      @event = event_name
    else
      raise TableSync::UndefinedEvent.new(event)
    end
  end

  def model=(model_name)
    @model = model_name.to_s
  end

  def configs
    @configs ||= begin
      configs = self.class.configs[model]
      configs = configs.sort_by { |config| "#{config.model.schema}.#{config.model.table}" }
      configs.map do |config|
        ::TableSync::Receiving::ConfigDecorator.new(
          config:,
          # next parameters will be send to each proc-options from config
          event:,
          model:,
          version:,
          project_id:,
          raw_data: data,
        )
      end
    end
  end

  def processed_data(config)
    version_key = config.option(:version_key, data:)
    data.filter_map do |row|
      next if config.option(:skip, row:)

      row = row.dup

      config.option(:mapping_overrides, row:).each do |before, after|
        row[after] = row.delete(before)
      end

      config.option(:except, row:).each { |x| row.delete(x) }

      row.merge!(config.option(:additional_data, row:))

      only = config.option(:only, row:)
      row, rest = row.partition { |key, _| key.in?(only) }.map(&:to_h)

      rest_key = config.option(:rest_key, row:, rest:)
      (row[rest_key] ||= {}).merge!(rest) if rest_key

      row[version_key] = version

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

  def validate_data_types(model, data)
    errors = model.validate_types(data)
    return if errors.nil?

    raise TableSync::DataError.new(data, errors.keys, errors.to_json)
  end

  def perform(config, params) # rubocop:disable Metrics/MethodLength
    model = config.model

    model.transaction do
      results = if event == :update
                  config.option(:before_update, **params)
                  validate_data_types(model, params[:data])
                  model.upsert(**params)
                else
                  config.option(:before_destroy, **params)
                  model.destroy(**params)
                end

      model.after_commit do
        TableSync::Instrument.notify table: model.table, schema: model.schema,
                                     count: results.count, event:, direction: :receive
      end

      if event == :update
        model.after_commit do
          config.option(:after_commit_on_update, **params, results:)

          hook = config.option(:on_first_sync)
          hook.perform(config:, targets: results) if hook.enabled?
        end
      else
        model.after_commit { config.option(:after_commit_on_destroy, **params, results:) }
      end
    end
  end

  def sort_key(value)
    value.is_a?(Comparable) ? value : value.to_s
  end
end
