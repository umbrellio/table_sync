# frozen_string_literal: true

class TableSync::Publishing::Message::Object < TableSync::Publishing::Message::Base
  private

  def object
    objects.first
  end

  def data
    TableSync::Publishing::Data::Object.new(
      object: object, state: state
    ).construct
  end

  def params
    TableSync::Publishing::Params::Object.new(object: object).construct
  end
end
