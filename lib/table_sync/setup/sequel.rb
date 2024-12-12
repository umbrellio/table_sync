# frozen_string_literal: true

module TableSync::Setup
  class Sequel < Base
    private

    def define_after_commit(event)
      options = options_exposed_for_block

      object_class.define_method("after_#{event}".to_sym) do
        if instance_eval(&options[:if]) && !instance_eval(&options[:unless])
          db.after_commit do
            TableSync::Publishing::Single.new(
              object_class: self.class.name,
              original_attributes: values,
              event:,
              debounce_time: options[:debounce_time],
            ).publish_later
          end
        end

        super()
      end
    end
  end
end
