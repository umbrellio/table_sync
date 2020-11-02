# frozen_string_literal: true

class TableSync::Publishing::Data::Object
  attribute :object

  private

  def attributes_for_sync
    TableSync::Publishing::Data::Attributes.new(
      object: object, destroy: destroyed?
    ).construct
  end

  def klass
    object.class
  end

  def metadata
    { created: created? }
  end
end