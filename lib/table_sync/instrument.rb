# frozen_string_literal: true

module TableSync::Instrument
  extend self

  def notify(**args)
    return unless TableSync.notify?
    raise(TableSync::InvalidConfig, error_message) if TableSync.notifier.nil?
    validate_args!(**args)

    TableSync.notifier.notify(**args)
  end

  private

  def error_message
    <<~MSG.squish
      Notifications are enabled, but no notifier is set in the config.
      Need to setup notifier by specifying TableSync#notifier setting.
    MSG
  end

  def validate_args!(**args)
    missing_keywords = required_args - args.compact.keys
    return if missing_keywords.blank?

    raise ArgumentError, "Missing keywords: #{missing_keywords.join(', ')}."
  end

  def required_args
    @required_args ||= %i[table schema event count direction].freeze
  end
end
