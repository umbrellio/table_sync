# frozen-string_literal: true

module TableSync::Setup
	class ActiveRecord < Base
	  private

	  def define_after_commit_on(event)
	    after_commit(on: event) do
	      return if not if_condition.call(self)
	      return if unless_condition.call(self)

	      enqueue_message(self.attributes)
	    end
	  end
	end
end