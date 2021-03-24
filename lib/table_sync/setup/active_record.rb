# frozen-string_literal: true

class TableSync::Setup::ActiveRecord < TableSync::Setup::Base
  private

  def define_after_commit_on(event)
    after_commit(on: event) do
      return if not if_condition.call(self)
      return if unless_condition.call(self)

      enqueue_message(self)
    end
  end

  def adapte
    TableSync::ORMAdapter::ActiveRecord
  end
end
