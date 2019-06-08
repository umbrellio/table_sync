# frozen_string_literal: true

module TableSync::ORMAdapter
  module Sequel
    module_function

    def model
      ::TableSync::Model::Sequel
    end

    def find(dataset, conditions)
      dataset.find(conditions)
    end

    def attributes(object)
      object.values
    end

    def setup_sync(klass, **opts)
      if_predicate     = to_predicate(opts.delete(:if), true)
      unless_predicate = to_predicate(opts.delete(:unless), false)
      raise "Only :if and :unless options are currently supported for Sequel hooks" if opts.any?

      { create: :created, update: :updated }.each do |event, state|
        klass.send(:define_method, :"after_#{event}") do
          if instance_eval(&if_predicate) && !instance_eval(&unless_predicate)
            db.after_commit do
              TableSync::Publisher.new(self.class.name, values, state: state).publish
            end
          end
          super()
        end
      end

      klass.send(:define_method, :after_destroy) do
        # publish anyway
        db.after_commit do
          TableSync::Publisher.new(self.class.name, values, state: :destroyed).publish
        end
        super()
      end
    end

    def to_predicate(val, default)
      return val.to_proc if val.respond_to?(:to_proc)

      -> (*) { default }
    end
  end
end
