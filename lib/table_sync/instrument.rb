# frozen_string_literal: true

module TableSync::Instrument
  NOTIFIER_REQUIRED_ARGS = %i[table schema event count direction].freeze

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
    missing_keywords = NOTIFIER_REQUIRED_ARGS - args.compact.keys
    return if missing_keywords.blank?

    raise ArgumentError, "Missing keywords: #{missing_keywords.join(', ')}."
  end
end
