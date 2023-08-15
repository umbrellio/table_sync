# frozen_string_literal: true

module TableSync::Utils::RequiredValidator
  module PrependedInitialization
    def initialize(*)
      super

      not_filled_attrs = calculate_not_filled_attributes
      if not_filled_attrs.present?
        raise(
          ArgumentError,
          "Some of required attributes is not provided: #{not_filled_attrs.inspect}",
        )
      end
    end
  end

  module ClassMethods
    def require_attributes(*attributes)
      _required_attributes.push(*attributes)
    end

    def _required_attributes
      @_required_attributes ||= []
    end
  end

  module InstanceMethods
    private

    def calculate_not_filled_attributes
      attributes
        .select { |key, value| key.in?(self.class._required_attributes) && value.blank? }
        .keys
    end
  end

  def self.included(klass)
    klass.prepend(PrependedInitialization)
    klass.extend(ClassMethods)
    klass.include(InstanceMethods)
  end
end
