# frozen_string_literal: true

module TableSync::Model
  class Sequel
    def initialize(table_name)
      @raw_model = Class.new(::Sequel::Model(table_name)).tap(&:unrestrict_primary_key)
    end

    def columns
      dataset.columns
    end

    def primary_keys
      [raw_model.primary_key].flatten
    end

    def upsert(data:, target_keys:, version_key:, first_sync_time_key:, default_values:)
      data = Array.wrap(data)
      qualified_version = ::Sequel.qualify(table_name, version_key)
      version_condition = ::Sequel.function(:coalesce, qualified_version, 0) <
                          ::Sequel.qualify(:excluded, version_key)

      upd_spec = update_spec(data.first.keys - target_keys)
      data.map! { |d| default_values.merge(d) }

      insert_data = type_cast(data)
      if first_sync_time_key
        insert_data.each { |datum| datum[first_sync_time_key] = Time.current }
      end

      result = dataset.returning
                      .insert_conflict(
                        target: target_keys,
                        update: upd_spec,
                        update_where: version_condition,
                      )
                      .multi_insert(insert_data)

      TableSync::Instrument.notify table: model_naming.table, schema: model_naming.schema,
                                   count: result.count, event: :update, direction: :receive
      result
    end

    def destroy(data)
      result = dataset.returning.where(data).delete
      TableSync::Instrument.notify table: model_naming.table, schema: model_naming.schema,
                                   count: result.count,
                                   event: :destroy, direction: :receive
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

    def table_name
      raw_model.table_name
    end

    def model_naming
      ::TableSync::NamingResolver::Sequel.new(table_name: table_name, db: db)
    end

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
      keys.map { |key| [key, ::Sequel[:excluded][key]] }.to_h
    end
  end
end
