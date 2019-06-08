# frozen_string_literal: true

module TableSync
  module EventActions
    def update(data)
      model.transaction do
        args = {
          data: data,
          target_keys: target_keys,
          version_key: version_key,
          first_sync_time_key: first_sync_time_key,
          default_values: default_values,
        }

        @config.callback_registry.get_callbacks(kind: :before_commit, event: :update).each do |cb|
          cb[data.values.flatten]
        end

        results = data.reduce([]) do |upserts, (part_model, part_data)|
          upserts + part_model.upsert(**args, data: part_data)
        end

        return if results.empty?
        raise TableSync::UpsertError.new(**args) unless correct_keys?(results)

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :update).each do |cb|
            cb[results]
          end
        end
      end
    end

    def destroy(data)
      attributes = data.first || {}
      target_attributes = attributes.select { |key| target_keys.include?(key) }

      model.transaction do
        @config.callback_registry.get_callbacks(kind: :before_commit, event: :destroy).each do |cb|
          cb[attributes]
        end

        results = model.destroy(target_attributes)

        return if results.empty?
        raise TableSync::DestroyError.new(target_attributes) if results.size != 1

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :destroy).each do |cb|
            cb[results]
          end
        end
      end
    end

    def correct_keys?(x)
      x.uniq { |d| d.slice(*target_keys) }.size == x.size
    end
  end
end
