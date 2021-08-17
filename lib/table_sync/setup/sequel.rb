# frozen-string_literal: true

module TableSync::Setup
  class Sequel < Base
    private

    def define_after_commit(event)
      options = options_exposed_for_block

      object_class.define_method("after_#{event}".to_sym) do
        return unless options[:if].call(self)
        return if options[:unless].call(self)

        TableSync::Publishing::Single.new(
          object_class: self.class.name,
          original_attributes: values,
          event: event,
          debounce_time: options[:debounce_time],
        ).publish_later

        super()
      end
    end
  end
end
