# frozen_string_literal: true

class TableSync::Publishing::Data::Batch
  attribute :objects

  private

  def klass
    objects.first.class
  end

  def attributes_for_sync
    objects.map do |object|
      TableSync::Publishing::Data::Attributes.new(
        object: object, destroy: destroyed?
      ).construct
    end
  end
end