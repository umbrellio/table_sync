# frozen_string_literal: true

module TableSync
  Error = Class.new(StandardError)

  NoObjectsForSyncError = Class.new(Error)

  class EventError < Error
    def initialize(event)
      super(<<~MSG.squish)
        Event #{event.inspect} is invalid.#{' '}
        Expected: #{TableSync::Event::VALID_RAW_EVENTS.inspect}.
      MSG
    end
  end

  class NoPrimaryKeyError < Error
    def initialize(object_class, object_data, primary_key_columns)
      super(<<~MSG.squish)
        Can't find or init an object of #{object_class} with #{object_data.inspect}.
        Incomplete primary key! object_data must contain: #{primary_key_columns.inspect}.
      MSG
    end
  end

  class NoCallableError < Error
    def initialize(type)
      super(<<~MSG.squish)
        Can't find callable for #{type}!
        Please initialize TableSync.#{type}_callable with the correct proc!
      MSG
    end
  end

  class UpsertError < Error
    def initialize(data:, target_keys:, result:)
      super("data: #{data.inspect}, target_keys: #{target_keys.inspect}, result: #{result.inspect}")
    end
  end

  class DestroyError < Error
    def initialize(data:, target_keys:, result:)
      super("data: #{data.inspect}, target_keys: #{target_keys.inspect}, result: #{result.inspect}")
    end
  end

  class DataError < Error
    def initialize(data, target_keys, description)
      super(<<~MSG.squish)
        #{description}
        target_keys: #{target_keys}
        data: #{data}
      MSG
    end
  end

  class InterfaceError < Error
    def initialize(object, method_name, parameters, description)
      parameters = parameters.map do |parameter|
        type, name = parameter

        case type
        when :req
          #:nocov:
          name.to_s
          #:nocov:
        when :keyreq
          "#{name}:"
        when :block
          "&#{name}"
        end
      end

      signature = "#{method_name}(#{parameters.join(", ")})"

      super("#{object} has to implement method `#{signature}`\n#{description}")
    end
  end

  UndefinedEvent = Class.new(Error)
  ORMNotSupported = Class.new(Error)

  class WrongOptionValue < Error
    def initialize(model, option, value)
      super("TableSync config for #{model.inspect} can't contain #{value.inspect} as #{option}")
    end
  end
end
