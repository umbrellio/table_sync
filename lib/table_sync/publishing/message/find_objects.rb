# frozen_string_literal: true

class TableSync::Publishing::Message::FindObjects
  include Tainbox
  include Memery

  attribute :klass
  attribute :attrs

  def initialize(**params)
    super(**params)

    self.klass = klass.constantize
    self.attrs = Array.wrap(attrs).map(&:deep_symbolize_keys)

    raise "Contains incomplete primary keys!" unless valid?
  end

  def list
    needles.map { |needle| find_object(needle) }
  end

  private

  def needles
    attrs.map { |attrs| attrs.slice(*primary_key_columns) }
  end

  def find_object(needle)
    TableSync.publishing_adapter.find(klass, needle)
  end

  memoize def primary_key_columns
    TableSync.publishing_adapter.primary_key_columns(klass)
  end

  # VALIDATION

  def valid?
    attrs.map(&:keys).all? { |keys| contains_pk?(keys) }
  end

  def contains_pk?(keys)
    (primary_key_columns - keys).empty?
  end
end