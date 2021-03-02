# frozen_string_literal: true

class TableSync::Publishing::BasePublisher
  include Memery

  BASE_SAFE_JSON_TYPES = [NilClass, String, TrueClass, FalseClass, Numeric, Symbol].freeze
  NOT_MAPPED = Object.new

  private

  attr_accessor :object_class

  # @!method job_callable
  # @!method job_callable_error_message
  # @!method attrs_for_callables
  # @!method attrs_for_routing_key
  # @!method attrs_for_metadata
  # @!method attributes_for_sync

  memoize def current_time
    Time.current
  end

  memoize def primary_keys
    Array(object_class.primary_key).map(&:to_sym)
  end

  memoize def attributes_for_sync_defined?
    object_class.method_defined?(:attributes_for_sync)
  end

  memoize def attrs_for_routing_key_defined?
    object_class.method_defined?(:attrs_for_routing_key)
  end

  memoize def attrs_for_metadata_defined?
    object_class.method_defined?(:attrs_for_metadata)
  end

  def resolve_routing_key
    routing_key_callable.call(object_class.name, attrs_for_routing_key)
  end

  def metadata
    TableSync.routing_metadata_callable&.call(object_class.name, attrs_for_metadata)
  end

  def confirm?
    @confirm
  end

  def routing_key_callable
    return TableSync.routing_key_callable if TableSync.routing_key_callable
    raise "Can't publish, set TableSync.routing_key_callable"
  end

  def filter_safe_for_serialization(object)
    case object
    when Array
      object.each_with_object([]) do |value, memo|
        value = filter_safe_for_serialization(value)
        memo << value if object_mapped?(value)
      end
    when Hash
      object.each_with_object({}) do |(key, value), memo|
        key = filter_safe_for_serialization(key)
        value = filter_safe_hash_values(value)
        memo[key] = value if object_mapped?(key) && object_mapped?(value)
      end
    when Float::INFINITY
      NOT_MAPPED
    when *BASE_SAFE_JSON_TYPES
      object
    else # rubocop:disable Lint/DuplicateBranch
      NOT_MAPPED
    end
  end

  def filter_safe_hash_values(value)
    case value
    when Symbol
      value.to_s
    else
      filter_safe_for_serialization(value)
    end
  end

  def object_mapped?(object)
    object != NOT_MAPPED
  end

  def job_class
    job_callable ? job_callable.call : raise(job_callable_error_message)
  end

  def publishing_data
    {
      model: object_class.try(:table_sync_model_name) || object_class.name,
      attributes: attributes_for_sync,
      version: current_time.to_f,
    }
  end

  def params
    params = {
      event: :table_sync,
      data: publishing_data,
      confirm_select: confirm?,
      routing_key: routing_key,
      realtime: true,
      headers: metadata,
    }

    params[:exchange_name] = TableSync.exchange_name if TableSync.exchange_name

    params
  end
end
