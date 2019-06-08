# frozen_string_literal: true

class TableSync::ReceivingHandler < Rabbit::EventHandler
  extend TableSync::DSL

  attribute :event
  attribute :model
  attribute :version

  def call
    raise TableSync::UndefinedConfig.new(model) if configs.blank?

    configs.each do |config|
      next unless config.allow_event?(event)

      data = processed_data(config)
      next if data.empty?

      case event
      when :update
        config.model.transaction do
          config.update(data)
        end
      when :destroy
        config.destroy(data.values.first)
      else
        raise "Unknown event: #{event}"
      end
    end
  end

  private

  def data=(data)
    @data = data[:attributes]
  end

  def event=(name)
    super(name.to_sym)
  end

  def model=(name)
    super(name.to_s)
  end

  def configs
    @configs ||= self.class.configs[model]
                     &.map { |c| ::TableSync::ConfigDecorator.new(c, self) }
  end

  def processed_data(config)
    parts = config.partitions&.transform_keys { |k| config.model.class.new(k) } ||
            { config.model => Array.wrap(data) }

    parts.transform_values! do |data_part|
      data_part.map do |row|
        original_row_for_data = row.dup
        row = row.dup

        config.mapping_overrides.each do |before, after|
          row[after] = row.delete(before)
        end

        only = config.only
        row, missed = row.partition { |key, _| key.in?(only) }.map(&:to_h)

        row.deep_merge!(config.rest_key => missed) if config.rest_key
        row[config.version_key] = version

        row.merge!(config.additional_data(original_row_for_data))

        row unless config.skip(original_row_for_data)
      end.compact.presence
    end.compact
  end
end
