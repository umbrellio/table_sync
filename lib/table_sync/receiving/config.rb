# frozen_string_literal: true

module TableSync::Receiving
  class Config
    attr_reader :model, :events

    def initialize(model:, events: TableSync::Event::VALID_RESOLVED_EVENTS)
      @model = model

      @events = [events].flatten.map(&:to_sym)

      raise TableSync::UndefinedEvent.new(events) if invalid_events.any?

      self.class.default_values_for_options.each do |ivar, default_value_generator|
        instance_variable_set(ivar, default_value_generator.call(self))
      end
    end

    def invalid_events
      events - TableSync::Event::VALID_RESOLVED_EVENTS
    end

    class << self
      attr_reader :default_values_for_options

      # In a configs these options are requested as they are
      # config.option - get value
      # config.option(args) - set static value
      # config.option { ... } - set proc as value

      def add_option(name, value_setter_wrapper:, value_as_proc_setter_wrapper:, default:)
        ivar = :"@#{name}"

        @default_values_for_options ||= {}
        @default_values_for_options[ivar] = default

        define_method(name) do |*value, &value_as_proc|
          return instance_variable_get(ivar) if value.empty? && value_as_proc.nil?

          value = value.first if value.size == 1

          if value_as_proc.present?
            new_value = TableSync::Utils.proc_keywords_resolver(&value_as_proc)
            setter_wrapper = value_as_proc_setter_wrapper
          else
            new_value = value
            setter_wrapper = value_setter_wrapper
          end

          old_value = instance_variable_get(ivar)
          result_value = instance_exec(name, new_value, old_value, &setter_wrapper)
          instance_variable_set(ivar, result_value)
        end
      end

      def add_simple_option(name)
        ivar = :"@#{name}"

        @default_values_for_options ||= {}
        @default_values_for_options[ivar] = proc { [nil, proc {}] }

        define_method(name) do |options = nil, &block|
          old_options, old_block = instance_variable_get(ivar)

          new_options = options || old_options
          new_block = block || old_block

          instance_variable_set(ivar, [new_options, new_block])
        end
      end
    end

    def allow_event?(name)
      events.include?(name)
    end

    def option(name)
      instance_variable_get(:"@#{name}")
    end
  end
end

# Helpers:

column_key = proc do |option_name, new_value|
  unless model.columns.include?(new_value)
    raise TableSync::WrongOptionValue.new(model, option_name, new_value)
  end
  new_value
end

exactly_symbol = proc do |option_name, new_value|
  unless new_value.is_a? Symbol
    raise TableSync::WrongOptionValue.new(model, option_name, new_value)
  end
  new_value
end

to_array = proc do |block|
  proc do |option_name, new_value|
    new_value = [new_value].flatten
    new_value.map { |value| instance_exec(option_name, value, &block) }
  end
end

exactly_not_array = proc do |block|
  proc do |option_name, new_value|
    if new_value.is_a? Array
      raise TableSync::WrongOptionValue.new(model, option_name, new_value)
    end
    instance_exec(option_name, new_value, &block)
  end
end

exactly_hash = proc do |block_for_keys, block_for_values|
  proc do |option_name, new_value|
    unless new_value.is_a? Hash
      raise TableSync::WrongOptionValue.new(model, option_name, new_value)
    end

    new_value.to_a.to_h do |key, value|
      [
        instance_exec("#{option_name} keys", key, &block_for_keys),
        instance_exec("#{option_name} values", value, &block_for_values),
      ]
    end
  end
end

any_value = proc do |_option_name, new_value|
  new_value
end

raise_error = proc do |option_name, new_value|
  raise TableSync::WrongOptionValue.new(model, option_name, new_value)
end

exactly_boolean = proc do |option_name, new_value|
  unless new_value.is_a?(TrueClass) || new_value.is_a?(FalseClass)
    raise TableSync::WrongOptionValue.new(model, option_name, new_value)
  end
  new_value
end

allow_false = proc do |block|
  proc do |option_name, new_value|
    next false if new_value.is_a? FalseClass
    instance_exec(option_name, new_value, &block)
  end
end

proc_result = proc do |block|
  proc do |option_name, new_value|
    proc do |*args, &b|
      result = new_value.call(*args, &b)
      instance_exec(option_name, result, &block)
    end
  end
end

accumulate_procs = proc do |block|
  proc do |option_name, new_value, old_value|
    old_value.push(&instance_exec(option_name, new_value, &block))
  end
end

# Options:

# rubocop:disable Layout/ArgumentAlignment

TableSync::Receiving::Config.add_option :only,
  value_setter_wrapper: to_array[column_key],
  value_as_proc_setter_wrapper: proc_result[to_array[column_key]],
  default: proc { |config| config.model.columns }

TableSync::Receiving::Config.add_option :target_keys,
  value_setter_wrapper: to_array[column_key],
  value_as_proc_setter_wrapper: proc_result[to_array[column_key]],
  default: proc { |config| Array.wrap(config.model.primary_keys) }

TableSync::Receiving::Config.add_option :rest_key,
  value_setter_wrapper: exactly_not_array[allow_false[column_key]],
  value_as_proc_setter_wrapper: proc_result[exactly_not_array[allow_false[column_key]]],
  default: proc { :rest }

TableSync::Receiving::Config.add_option :version_key,
  value_setter_wrapper: exactly_not_array[column_key],
  value_as_proc_setter_wrapper: proc_result[exactly_not_array[column_key]],
  default: proc { :version }

TableSync::Receiving::Config.add_option :except,
  value_setter_wrapper: to_array[exactly_symbol],
  value_as_proc_setter_wrapper: proc_result[to_array[exactly_symbol]],
  default: proc { [] }

TableSync::Receiving::Config.add_option :mapping_overrides,
  value_setter_wrapper: exactly_hash[exactly_symbol, exactly_symbol],
  value_as_proc_setter_wrapper: proc_result[exactly_hash[exactly_symbol, exactly_symbol]],
  default: proc { {} }

TableSync::Receiving::Config.add_option :additional_data,
  value_setter_wrapper: exactly_hash[exactly_symbol, any_value],
  value_as_proc_setter_wrapper: proc_result[exactly_hash[exactly_symbol, any_value]],
  default: proc { {} }

TableSync::Receiving::Config.add_option :default_values,
  value_setter_wrapper: exactly_hash[exactly_symbol, any_value],
  value_as_proc_setter_wrapper: proc_result[exactly_hash[exactly_symbol, any_value]],
  default: proc { {} }

TableSync::Receiving::Config.add_option :skip,
  value_setter_wrapper: exactly_boolean,
  value_as_proc_setter_wrapper: proc_result[exactly_boolean],
  default: proc { false }

TableSync::Receiving::Config.add_option :wrap_receiving,
  value_setter_wrapper: raise_error,
  value_as_proc_setter_wrapper: any_value,
  default: proc { proc { |&block| block.call } }

TableSync::Receiving::Config.add_simple_option :on_first_sync

%i[
  before_update
  after_commit_on_update
  before_destroy
  after_commit_on_destroy
].each do |option|
  TableSync::Receiving::Config.add_option option,
    value_setter_wrapper: raise_error,
    value_as_proc_setter_wrapper: accumulate_procs[any_value],
    default: (proc do |_config|
      TableSync::Utils::ProcArray.new do |array, args, &block|
        array.map { |pr| pr.call(*args, &block) }
      end
    end)
end

# rubocop:enable Layout/ArgumentAlignment
