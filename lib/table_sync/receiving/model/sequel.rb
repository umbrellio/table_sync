# frozen_string_literal: true

module TableSync::Receiving::Model
  class Sequel
    attr_reader :table, :schema

    ISOLATION_LEVELS = {
      uncommitted: :uncommitted,
      committed: :committed,
      repeatable: :repeatable,
      serializable: :serializable,
    }.freeze

    def initialize(table_name)
      @raw_model = Class.new(::Sequel::Model(table_name)).tap(&:unrestrict_primary_key)
      @types_validator = TableSync::Utils::Schema::Builder::Sequel.build(@raw_model)

      model_naming = ::TableSync::NamingResolver::Sequel.new(
        table_name:,
        db: @raw_model.db,
      )

      @table = model_naming.table.to_sym
      @schema = model_naming.schema.to_sym
    end

    def isolation_level(lookup_code)
      ISOLATION_LEVELS.fetch(lookup_code)
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
      sanitized_data = data.map { |attr| attr.slice(*target_keys) }
      sanitized_data = type_cast(sanitized_data)
      result = dataset.returning.where(::Sequel.|(*sanitized_data)).delete

      if result.size > data.size
        raise TableSync::DestroyError.new(data:, target_keys:, result:)
      end

      result
    end

    def validate_types(data)
      types_validator.validate(data)
    end

    def transaction(**params, &)
      db.transaction(**params, &)
    end

    def after_commit(&)
      db.after_commit(&)
    end

    def try_advisory_lock(lock_key)
      transaction do
        if db.get(::Sequel.function(:pg_try_advisory_xact_lock, lock_key.to_i))
          yield
        end
      end
    end

    def find_and_save(keys:)
      entry = dataset.first(keys)
      return unless entry

      yield entry
      entry.save_changes
    end

    private

    attr_reader :raw_model, :types_validator

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
