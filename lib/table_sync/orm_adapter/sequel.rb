# frozen_string_literal: true

module TableSync::ORMAdapter
  module Sequel
    module_function

    def model
      ::TableSync::Model::Sequel
    end

    def model_naming(object)
      ::TableSync::NamingResolver::Sequel.new(table_name: object.table_name, db: object.db)
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
      debounce_time    = opts.delete(:debounce_time)

      if opts.any?
        raise "Only :if, :skip_debounce and :unless options are currently " \
              "supported for Sequel hooks"
      end

      register_callbacks(klass, if_predicate, unless_predicate, debounce_time)
    end

    def to_predicate(val, default)
      return val.to_proc if val.respond_to?(:to_proc)

      -> (*) { default }
    end

    def register_callbacks(klass, if_predicate, unless_predicate, debounce_time)
      { create: :created, update: :updated }.each do |event, state|
        klass.send(:define_method, :"after_#{event}") do
          if instance_eval(&if_predicate) && !instance_eval(&unless_predicate)
            db.after_commit do
              TableSync::Publisher.new(self.class.name, values,
                                       state: state, debounce_time: debounce_time).publish
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
  end
end
