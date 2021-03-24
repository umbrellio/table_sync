# frozen_string_literal: true

class TableSync::Publishing::Message::Single < TableSync::Publishing::Message::Base
  private

  def params
    TableSync::Publishing::Params::Single.new(object: object).construct
  end
end
