# frozen_string_literal: true

require "memery"
require "self_data"
require "rabbit_messaging"
require "rabbit/event_handler" # NOTE: from rabbit_messaging"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/numeric/time"

module TableSync
  require_relative "table_sync/utils"
  require_relative "table_sync/version"
  require_relative "table_sync/errors"
  require_relative "table_sync/plugins"
  require_relative "table_sync/instrument"
  require_relative "table_sync/instrument_adapter/active_support"
  require_relative "table_sync/naming_resolver/active_record"
  require_relative "table_sync/naming_resolver/sequel"
  require_relative "table_sync/receiving"
  require_relative "table_sync/publishing"

  # @api public
  # @since 2.2.0
  extend Plugins::AccessMixin

  class << self
    attr_accessor :publishing_job_class_callable
    attr_accessor :batch_publishing_job_class_callable
    attr_accessor :routing_key_callable
    attr_accessor :exchange_name
    attr_accessor :routing_metadata_callable
    attr_accessor :notifier
    attr_reader :orm
    attr_reader :publishing_adapter
    attr_reader :receiving_model

    def sync(klass, **opts)
      publishing_adapter.setup_sync(klass, opts)
    end

    def orm=(val)
      case val
      when :active_record
        @publishing_adapter = Publishing::ORMAdapter::ActiveRecord
        @receiving_model = Receiving::Model::ActiveRecord
      when :sequel
        @publishing_adapter = Publishing::ORMAdapter::Sequel
        @receiving_model = Receiving::Model::Sequel
      else
        raise ORMNotSupported.new(val.inspect)
      end

      @orm = val
    end
  end
end
