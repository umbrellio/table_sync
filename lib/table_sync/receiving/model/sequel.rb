# frozen_string_literal: true

module TableSync::Receiving::Model
  class Sequel
    attr_reader :table, :schema

    def initialize(table_name)
      @raw_model = Class.new(::Sequel::Model(table_name)).tap(&:unrestrict_primary_key)

      model_naming = ::TableSync::NamingResolver::Sequel.new(
        table_name: table_name,
        db: @raw_model.db,
      )

      @table = model_naming.table.to_sym
      @schema = model_naming.schema.to_sym
    end

    def columns
      dataset.columns
    end

    def primary_keys
      [raw_model.primary_key].flatten
    end

    def upsert(data:, target_keys:, version_key:, default_values:)
      qualified_version = ::Sequel.qualify(raw_model.table_name, version_key)
      version_condition = ::Sequel.function(:coalesce, qualified_version, 0) <
                          ::Sequel.qualify(:excluded, version_key)

      upd_spec = update_spec(data.first.keys - target_keys)
      data.map! { |d| default_values.merge(d) }

      insert_data = type_cast(data)

      dataset
        .returning
        .insert_conflict(target: target_keys, update: upd_spec, update_where: version_condition)
        .multi_insert(insert_data)
    end

    def destroy(data:, target_keys:, version_key:)
      sanitized_data = data.map { |attr| attr.select { |key, _value| target_keys.include?(key) } }
      sanitized_data = type_cast(sanitized_data)
      result = dataset.returning.where(::Sequel.|(*sanitized_data)).delete

      if result.size > data.size
        raise TableSync::DestroyError.new(data: data, target_keys: target_keys, result: result)
      end

      result
    end

    def transaction(&block)
      db.transaction(&block)
    end

    def after_commit(&block)
      db.after_commit(&block)
    end

    private

    attr_reader :raw_model

    def dataset
      raw_model.dataset
    end

    def db
      dataset.db
    end

    def type_cast(data)
      data.map { |d| raw_model.new(d).values.keep_if { |k| d.key?(k) } }
    end

    def update_spec(keys)
      keys.to_h { |key| [key, ::Sequel[:excluded][key]] }
    end
  end
end
