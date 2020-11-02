# frozen_string_literal: true

class TableSync::Publishing::Message
  include Tainbox

  attribute :klass
  attribute :primary_keys
  attribute :options

  attr_accessor :params, :publishing_data

  def initialize(params)
    super(params)

    init_klass

    wrap_and_symbolize_primary_keys
    validate_primary_keys

    init_params
    init_publishing_data
  end

  def publish
    Rabbit.publish(message_params)
  end

  def message_params
    params.merge(data: publishing_data)
  end

  # INITIALIZATION

  def init_klass
    self.klass = klass.constantize # Object.const_get(klass)
  end

  def wrap_and_symbolize_primary_keys
    self.primary_keys = Array.wrap(primary_keys).map(&:symbolize_keys)
  end

  def validate_primary_keys
    TableSync::Publishing::Message::Validate.new(klass, primary_keys).call!
  end

  def init_params
    self.params = if batch?
      TableSync::Publishing::Message::Batch::Params.new(options).call
    else 
      TableSync::Publishing::Message::Params.new(object).call
    end
  end

  def init_publishing_data
    self.publishing_data = TableSync::Publishing::Message::Params.new(
      klass: klass, primary_keys: primary_keys,
    ).call
  end

  def batch?
    primary_keys.size >1
  end
end
