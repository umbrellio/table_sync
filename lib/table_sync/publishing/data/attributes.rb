# frozen_string_literal: true

class TableSync::Publishing::Data::Attributes
  include Tainbox

  attribute :object
  attribute :destroy

  # Can't find object when destruction!

  def for_sync
    destroy ? attributes_for_destroy : attributes_for_update
  end

  private

  def attributes_for_destroy
    object.try(:table_sync_destroy_attributes) ||
    TableSync.publishing_adapter.primary_key(object)
  end

  def attributes_for_update
    object.try(:attributes_for_sync) ||
    TableSync.publishing_adapter.attributes(object)
  end
end