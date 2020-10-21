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

      params = { data: data, target_keys: target_keys, version_key: version_key }

      if event == :update
        params[:default_values] = config.default_values(data: data)
      end

      config.wrap_receiving(**params) do
        perform(config, params)
      end
    end
  end

  private

  # redefine setter from Rabbit::EventHandler
  def data=(data)
    super(Array.wrap(data[:attributes]))
  end

  def event=(name)
    name = name.to_sym
    raise TableSync::UndefinedEvent.new(event) unless %i[update destroy].include?(name)
    super(name)
  end

  def model=(name)
    super(name.to_s)
  end

  def configs
    @configs ||= self.class.configs[model]&.map do |config|
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

  def processed_data(config)
    data.map do |row|
      next if config.skip(row: row)

      row = row.dup

      config.mapping_overrides(row: row).each do |before, after|
        row[after] = row.delete(before)
      end

      config.except(row: row).each(&row.method(:delete))

      row.merge!(config.additional_data(row: row))

      only = config.only(row: row)
      row, rest = row.partition { |key, _| key.in?(only) }.map(&:to_h)

      rest_key = config.rest_key(row: row, rest: rest)
      (row[rest_key] ||= {}).merge!(rest) if rest_key

      row
    end.compact
  end

  def validate_data(data, target_keys:)
    data.each do |row|
      next if target_keys.all?(&row.keys.method(:include?))
      raise TableSync::DataError.new(
        data, target_keys, "Some target keys not found in received attributes!"
      )
    end

    if data.uniq { |row| row.slice(*target_keys) }.size != data.size
      raise TableSync::DataError.new(
        data, target_keys, "Duplicate rows found!"
      )
    end
  end

  def perform(config, params)
    model = config.model

    model.transaction do
      if event == :update
        config.before_update(**params)

        results = model.upsert(**params)

        model.after_commit do
          config.after_commit_on_update(**params.merge(results: results))
        end
      else
        config.before_destroy(**params)

        results = model.destroy(**params)

        model.after_commit do
          config.after_commit_on_destroy(**params.merge(results: results))
        end
      end
    end
  end
end
