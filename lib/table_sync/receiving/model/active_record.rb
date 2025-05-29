# frozen_string_literal: true

module TableSync::Receiving::Model
  class ActiveRecord
    class AfterCommitWrap
      def initialize(&block)
        @callback = block
      end

      def committed!(*)
        @callback.call
      end

      def before_committed!(*); end

      def rolledback!(*); end

      def trigger_transactional_callbacks?(*); end
    end

    attr_reader :table, :schema

    def initialize(table_name)
      @raw_model = Class.new(::ActiveRecord::Base) do
        self.table_name = table_name
        self.inheritance_column = nil
      end

      model_naming = ::TableSync::NamingResolver::ActiveRecord.new(table_name:)

      @table = model_naming.table.to_sym
      @schema = model_naming.schema.to_sym
    end

    def columns
      raw_model.column_names.map(&:to_sym)
    end

    def primary_keys
      db.execute(<<~SQL).column_values(0).map(&:to_sym)
        SELECT kcu.column_name
        FROM INFORMATION_SCHEMA.TABLES t
        LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
          ON tc.table_catalog = t.table_catalog
          AND tc.table_schema = t.table_schema
          AND tc.table_name = t.table_name
          AND tc.constraint_type = 'PRIMARY KEY'
        LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
          ON kcu.table_catalog = tc.table_catalog
          AND kcu.table_schema = tc.table_schema
          AND kcu.table_name = tc.table_name
          AND kcu.constraint_name = tc.constraint_name
        WHERE
          t.table_schema NOT IN ('pg_catalog', 'information_schema')
          AND t.table_schema = '#{schema}'
          AND t.table_name = '#{table}'
        ORDER BY
          kcu.ordinal_position
      SQL
    end

    def upsert(data:, target_keys:, version_key:, default_values:)
      data.filter_map do |datum|
        conditions = datum.select { |k| target_keys.include?(k) }

        row = raw_model.lock("FOR NO KEY UPDATE").where(conditions)

        if row.to_a.size > 1
          raise TableSync::UpsertError.new(data: datum, target_keys:, result: row)
        end

        row = row.first

        if row
          next if datum[version_key] <= row[version_key]

          row.update!(datum)
        else
          create_data = default_values.merge(datum)
          row = raw_model.create!(create_data)
        end

        row_to_hash(row)
      end
    end

    def destroy(data:, target_keys:, version_key:)
      sanitized_data = data.map { |attr| attr.slice(*target_keys) }

      query = nil
      sanitized_data.each_with_index do |row, index|
        if index == 0
          query = raw_model.lock("FOR UPDATE").where(row)
        else
          query = query.or(raw_model.lock("FOR UPDATE").where(row))
        end
      end

      result = query.destroy_all.map { |x| row_to_hash(x) }

      if result.size > data.size
        raise TableSync::DestroyError.new(data:, target_keys:, result:)
      end

      result
    end

    def transaction(&)
      ::ActiveRecord::Base.transaction(&)
    end

    def after_commit(&)
      db.add_transaction_record(AfterCommitWrap.new(&))
    end

    private

    attr_reader :raw_model

    def db
      raw_model.connection
    end

    def row_to_hash(row)
      row.attributes.transform_keys(&:to_sym)
    end
  end
end
