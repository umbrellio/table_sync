# frozen_string_literal: true

module TableSync::Model
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
    end

    def initialize(table_name)
      @raw_model = Class.new(::ActiveRecord::Base) do
        self.table_name = table_name
        self.inheritance_column = nil
      end
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
          AND t.table_schema = '#{table_info[:schema]}'
          AND t.table_name = '#{table_info[:name]}'
        ORDER BY
          kcu.ordinal_position
      SQL
    end

    def upsert(data:, target_keys:, version_key:, first_sync_time_key:, default_values:)
      data = Array.wrap(data)

      TableSync::Instrument.update(table_info[:name]) do
        transaction do
          data.map do |datum|
            conditions = datum.select { |k| target_keys.include?(k) }

            row = raw_model.lock("FOR NO KEY UPDATE").find_by(conditions)
            if row
              next if datum[version_key] <= row[version_key]

              row.update!(datum)
            else
              create_data = datum.merge(default_values)
              create_data[first_sync_time_key] = Time.current if first_sync_time_key
              row = raw_model.create!(create_data)
            end

            row_to_hash(row)
          end.compact
        end
      end
    end

    def destroy(data)
      TableSync::Instrument.destroy(table_info[:name]) do
        transaction do
          row = raw_model.lock("FOR UPDATE").find_by(data)&.destroy!
          [row_to_hash(row)]
        end
      end
    end

    def transaction(&block)
      ::ActiveRecord::Base.transaction(&block)
    end

    def after_commit(&block)
      db.add_transaction_record(AfterCommitWrap.new(&block))
    end

    private

    attr_reader :raw_model

    def table_info
      keys = raw_model.table_name.split(".")
      name = keys[-1]
      schema = keys[-2] || "public"
      { schema: schema, name: name }
    end

    def db
      @raw_model.connection
    end

    def row_to_hash(row)
      row.attributes.each_with_object({}) { |(k, v), o| o[k.to_sym] = v }
    end
  end
end
