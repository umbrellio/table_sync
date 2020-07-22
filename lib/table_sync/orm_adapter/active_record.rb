# frozen_string_literal: true

module TableSync::ORMAdapter
  module ActiveRecord
    module_function

    def model
      ::TableSync::Model::ActiveRecord
    end

    def model_naming(object)
      ::TableSync::NamingResolver::ActiveRecord.new(table_name: object.table_name)
    end

    def find(dataset, conditions)
      dataset.find_by(conditions)
    end

    def attributes(object)
      object.attributes
    end

    def setup_sync(klass, opts)
      debounce_time = opts.delete(:debounce_time)

      klass.instance_exec do
        { create: :created, update: :updated, destroy: :destroyed }.each do |event, state|
          after_commit(on: event, **opts) do
            TableSync::Publisher.new(self.class.name, attributes,
                                     state: state, debounce_time: debounce_time).publish
          end
        end
      end
    end
  end
end
