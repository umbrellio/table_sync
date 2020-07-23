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
      prevent_empty_destroy_event!(data)

      target_attributes = data.map { |attrs| attrs.slice(*target_keys) }

      prevent_incomplete_event!(target_attributes)

      with_wrapping(DataWrapper::Destroy.new(data)) do
        process_destroy(data, target_attributes)
      end
    end

    def process_upsert(data) # rubocop:disable Metrics/MethodLength
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
        raise TableSync::UpsertError.new(**args) unless expected_update_result?(results)

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :update).each do |cb|
            cb[results]
          end
        end
      end
    end

    def process_destroy(attributes, target_attributes)
      model.transaction do
        @config.callback_registry.get_callbacks(kind: :before_commit, event: :destroy).each do |cb|
          cb[attributes]
        end

        if on_destroy
          results = on_destroy.call(attributes: attributes, target_keys: target_keys)
        else
          results = model.destroy(target_attributes)

          return if results.empty?

          if results.size > size_of_attrs(target_attributes)
            raise TableSync::DestroyError.new(target_attributes)
          end
        end

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :destroy).each do |cb|
            cb[results]
          end
        end
      end
    end

    def size_of_attrs(attrs)
      attrs.is_a?(Array) ? attrs.size : 1
    end

    def with_wrapping(data = [], &block)
      if @config.wrap_receiving
        @config.wrap_receiving.call(data, block)
      else
        yield
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

    def prevent_empty_destroy_event!(data)
      raise TableSync::EmptyAttributesError.new(data) if data.any?(&:empty?)
    end
  end
end
