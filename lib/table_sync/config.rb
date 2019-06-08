# frozen_string_literal: true

module TableSync
  class Config
    attr_reader :model, :events, :callback_registry

    def initialize(model:, events: nil)
      @model = model
      @events = events.nil? ? nil : [events].flatten.map(&:to_sym)

      @callback_registry = CallbackRegistry.new

      only(model.columns)
      mapping_overrides({})
      additional_data({})
      default_values({})
      @rest_key = :rest
      @version_key = :version
      @first_sync_time_key = nil
      target_keys(model.primary_keys)
    end

    # add_option implements next logic
    # config.option - get value
    # config.option(args) - set static value
    # config.option { ... } - set proc as value
    def self.add_option(name, &option_block)
      ivar = "@#{name}".to_sym

      option_block ||= proc { |value| value }

      define_method(name) do |*args, &block|
        if args.empty? && block.nil?
          instance_variable_get(ivar)
        elsif block
          params = block.parameters.map { |param| param[0] == :keyreq ? param[1] : nil }.compact
          unified_block = proc { |hash = {}| block.call(hash.slice(*params)) }
          instance_variable_set(ivar, unified_block)
        else
          instance_variable_set(ivar, instance_exec(*args, &option_block))
        end
      end
    end

    def allow_event?(name)
      return true if events.nil?
      events.include?(name)
    end

    def before_commit(on:, &block)
      callback_registry.register_callback(block, kind: :before_commit, event: on.to_sym)
    end

    def after_commit(on:, &block)
      callback_registry.register_callback(block, kind: :after_commit, event: on.to_sym)
    end

    check_and_set_column_key = proc do |key|
      key = key.to_sym
      raise "#{model.inspect} doesn't have key: #{key}" unless model.columns.include?(key)
      key
    end

    set_column_keys = proc do |*keys|
      [keys].flatten.map { |k| instance_exec(k, &check_and_set_column_key) }
    end

    add_option(:only, &set_column_keys)
    add_option(:target_keys, &set_column_keys)
    add_option(:rest_key) do |value|
      value ? instance_exec(value, &check_and_set_column_key) : nil
    end
    add_option(:version_key, &check_and_set_column_key)
    add_option(:first_sync_time_key) do |value|
      value ? instance_exec(value, &check_and_set_column_key) : nil
    end

    add_option(:mapping_overrides)
    add_option(:additional_data)
    add_option(:default_values)
    add_option(:partitions)
    add_option(:skip)
  end
end
