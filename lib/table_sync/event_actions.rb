# frozen_string_literal: true

module TableSync
  module EventActions
    def update(data)
      prevent_incomplete_event!(data.values.flatten)

      with_wrapping(DataWrapper::Update.new(data)) do
        process_upsert(data)
      end
    end

    def destroy(data)
      target_attributes = data.map { |attrs| attrs.slice(*target_keys) }

      prevent_incomplete_event!(target_attributes)

      with_wrapping(DataWrapper::Destroy.new(data)) do
        process_destroy(data, target_attributes)
      end
    end

    def process_upsert(data)
      model.transaction do
        args = {
          data: data,
          target_keys: target_keys,
          version_key: version_key,
          first_sync_time_key: first_sync_time_key,
          default_values: default_values,
        }

        run_callbacks(:before_commit, :update, data.values.flatten)

        results = data.reduce([]) do |upserts, (part_model, part_data)|
          upserts + part_model.upsert(**args, data: part_data)
        end

        return if results.empty?
        raise TableSync::UpsertError.new(**args) unless expected_update_result?(results)

        @config.model.after_commit do
          run_callbacks(:after_commit, :update, results)
        end
      end
    end

    def process_destroy(attributes, target_attributes)
      model.transaction do
        run_callbacks(:before_commit, :destroy, attributes)

        if on_destroy
          results = on_destroy.call(attributes: attributes, target_keys: target_keys)
        else
          results = model.destroy(target_attributes)
        end

        if results.any?
          prevent_inconsistent_destroy!(results, target_attributes)

          @config.model.after_commit do
            run_callbacks(:after_commit, :destroy, results)
          end
        end
      end
    end

    def with_wrapping(data = [], &block)
      if @config.wrap_receiving
        @config.wrap_receiving.call(data, block)
      else
        yield
      end
    end

    def prevent_inconsistent_destroy!(destroy_result, target_attributes)
      if destroy_result.size > Array(target_attributes).size
        raise TableSync::DestroyError.new(target_attributes)
      end
    end

    def expected_update_result?(query_results)
      query_results.uniq { |d| d.slice(*target_keys) }.size == query_results.size
    end

    def prevent_incomplete_event!(data)
      keys = data.map(&:keys).uniq

      unless keys.all? { |key_set| (target_keys - key_set).empty? }
        raise TableSync::UnprovidedEventTargetKeysError.new(target_keys, keys)
      end
    end

    def run_callbacks(kind, event, data)
      @config.callback_registry.get_callbacks(kind: kind, event: event).each do |cb|
        cb[data]
      end
    end
  end
end
