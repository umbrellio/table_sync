# frozen_string_literal: true

# check if works!
module TableSync::Publishing::Data
	class Raw
		include Tainbox

  	attribute :object_class
  	attribute :attributes_for_sync
	end
end
