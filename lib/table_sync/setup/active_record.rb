# frozen-string_literal: true

module TableSync::Setup
  class ActiveRecord < Base
    private

    def define_after_commit(event)
      options = options_exposed_for_block

      object_class.after_commit(on: event) do
        return if (self.new_record? && self.destroyed?)

        if instance_eval(&options[:if]) && !instance_eval(&options[:unless])
          TableSync::Publishing::Single.new(
            object_class: self.class.name,
            original_attributes: attributes,
            event: event,
            debounce_time: options[:debounce_time],
          ).publish_later
        end
      end
    end
  end
end
