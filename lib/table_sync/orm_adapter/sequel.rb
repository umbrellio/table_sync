# frozen_string_literal: true

module TableSync::ORMAdapter
	class Sequel < Base
    def primary_key
      object.pk_hash
    end

    def attributes
      object.values
    end

    def find
      @object = object_class.find(needle)

      super
    end
  end
end
