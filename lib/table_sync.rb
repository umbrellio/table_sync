# frozen_string_literal: true

require "memery"
require "rabbit_messaging"
require "rabbit/event_handler" # NOTE: from rabbit_messaging"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/numeric/time"

module TableSync
  require_relative "table_sync/version"
  require_relative "table_sync/errors"
  require_relative "table_sync/plugins"
  require_relative "table_sync/event_actions"
  require_relative "table_sync/event_actions/data_wrapper"
  require_relative "table_sync/config"
  require_relative "table_sync/config/callback_registry"
  require_relative "table_sync/config_decorator"
  require_relative "table_sync/dsl"
  require_relative "table_sync/receiving_handler"
  require_relative "table_sync/base_publisher"
  require_relative "table_sync/publisher"
  require_relative "table_sync/batch_publisher"
  require_relative "table_sync/orm_adapter/active_record"
  require_relative "table_sync/orm_adapter/sequel"
  require_relative "table_sync/model/active_record"
  require_relative "table_sync/model/sequel"
  require_relative "table_sync/instrument"
  require_relative "table_sync/instrument_adapter/active_support"
  require_relative "table_sync/naming_resolver/active_record"
  require_relative "table_sync/naming_resolver/sequel"

  # @api public
  # @since 2.3.0
  extend Plugins::AccessMixin

  class << self
    include Memery

    attr_accessor :publishing_job_class_callable
    attr_accessor :batch_publishing_job_class_callable
    attr_accessor :routing_key_callable
    attr_accessor :exchange_name
    attr_accessor :routing_metadata_callable
    attr_accessor :notifier

    def sync(*args)
      orm.setup_sync(*args)
    end

    def orm=(val)
      clear_memery_cache!
      @orm = val
    end

    memoize def orm
      case @orm
      when :active_record
        ORMAdapter::ActiveRecord
      when :sequel
        ORMAdapter::Sequel
      else
        raise "ORM not supported: #{@orm.inspect}"
      end
    end
  end
end
