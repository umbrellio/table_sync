# frozen-string_literal: true

class TableSync::Setup::Sequel < TableSync::Setup::Base
  private

  def define_after_commit_on(event)
    define_method("after_#{event}".to_sym) do
      return if not if_condition.call(self)
      return if unless_condition.call(self)

      enqueue_message(self)

      super()
    end
  end

  def adapter
    TableSync::ORMAdapter::Sequel
  end
end
