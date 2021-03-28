# frozen-string_literal: true

module TableSync::Setup
	class Sequel < Base
	  private

	  def define_after_commit_on(event)
	    define_method("after_#{event}".to_sym) do
	      return if not if_condition.call(self)
	      return if unless_condition.call(self)

	      enqueue_message(self.values)

	      super()
	    end
	  end
	end
end
