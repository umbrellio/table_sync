# frozen_string_literal: true

module TableSync::ORMAdapter
  module ActiveRecord
    module_function

    def model
      ::TableSync::Model::ActiveRecord
    end

    def find(dataset, conditions)
      dataset.find_by(conditions)
    end

    def attributes(object)
      object.attributes
    end

    def table_name(object)
      object.table_name
    end

    def setup_sync(klass, **opts)
      klass.instance_exec do
        { create: :created, update: :updated, destroy: :destroyed }.each do |event, state|
          after_commit(on: event, **opts) do
            TableSync::Publisher.new(self.class.name, attributes, state: state).publish
          end
        end
      end
    end
  end
end
