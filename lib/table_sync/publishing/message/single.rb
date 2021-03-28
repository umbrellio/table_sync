# frozen_string_literal: true

module TableSync::Publishing::Message
	class Single < Base
	  private

	  def params
	    TableSync::Publishing::Params::Single.new(object: object).construct
	  end
	end
end
