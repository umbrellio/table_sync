# frozen_string_literal: true

require "memery"
require "self_data"
require "rabbit_messaging"
require "rabbit/event_handler" # NOTE: from rabbit_messaging"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/numeric/time"

module TableSync
  require_relative "table_sync/event"
  require_relative "table_sync/utils"
  require_relative "table_sync/version"
  require_relative "table_sync/errors"

  require_relative "table_sync/instrument"
  require_relative "table_sync/instrument_adapter/active_support"

  require_relative "table_sync/naming_resolver/active_record"
  require_relative "table_sync/naming_resolver/sequel"

  require_relative "table_sync/orm_adapter/base"
  require_relative "table_sync/orm_adapter/active_record"
  require_relative "table_sync/orm_adapter/sequel"

  require_relative "table_sync/receiving"
  require_relative "table_sync/publishing"

  require_relative "table_sync/setup/base"
  require_relative "table_sync/setup/active_record"
  require_relative "table_sync/setup/sequel"

  class << self
    attr_accessor :raise_on_empty_message
    attr_accessor :single_publishing_job_class_callable
    attr_accessor :batch_publishing_job_class_callable
    attr_accessor :routing_key_callable
    attr_accessor :exchange_name
    attr_accessor :headers_callable
    attr_accessor :notify

    attr_reader :orm
    attr_reader :publishing_adapter
    attr_reader :receiving_model
    attr_reader :setup
    attr_reader :notifier

    def sync(object_class, **options)
      setup.new(
        object_class: object_class,
        on: options[:on],
        if_condition: options[:if],
        unless_condition: options[:unless],
        debounce_time: options[:debounce_time],
      ).register_callbacks
    end

    def orm=(val)
      case val
      when :active_record
        @publishing_adapter = TableSync::ORMAdapter::ActiveRecord
        @receiving_model    = Receiving::Model::ActiveRecord
        @setup              = TableSync::Setup::ActiveRecord
      when :sequel
        @publishing_adapter = TableSync::ORMAdapter::Sequel
        @receiving_model    = Receiving::Model::Sequel
        @setup              = TableSync::Setup::Sequel
      else
        raise ORMNotSupported.new(val.inspect)
      end

      @orm = val
    end

    def notifier=(value)
      self.notify = true if notify.nil?

      @notifier = value
    end

    def notify?
      !!notify
    end
  end
end
