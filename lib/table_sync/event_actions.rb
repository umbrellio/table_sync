# frozen_string_literal: true

module TableSync
  module EventActions
    def update(data)
      data.each_value do |attribute_set|
        attribute_set.each do |attributes|
          prevent_incomplete_event!(attributes)
        end
      end

      with_wrapping(DataWrapper::Update.new(data)) do
        process_upsert(data)
      end
    end

    def destroy(data)
      attributes = data.first || {}
      target_attributes = attributes.select { |key, _value| target_keys.include?(key) }
      prevent_incomplete_event!(target_attributes)

      with_wrapping(DataWrapper::Destroy.new(attributes)) do
        process_destroy(attributes, target_attributes)
      end
    end

    def process_upsert(data) # rubocop:disable Metrics/MethodLength
      model.transaction do
        upsert_data = TableSync::EventActions::DataWrapper::Update.new(data)
        @config.inside_transaction_before.each { |block| block.call(upsert_data) }

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

        @config.inside_transaction_after.each { |block| block.call(upsert_data) }

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :update).each do |cb|
            cb[results]
          end
        end
      end
    end

    def process_destroy(attributes, target_attributes)
      model.transaction do
        destroy_data = TableSync::EventActions::DataWrapper::Destroy.new(attributes)
        @config.inside_transaction_before.each { |block| block.call(destroy_data) }

        @config.callback_registry.get_callbacks(kind: :before_commit, event: :destroy).each do |cb|
          cb[attributes]
        end

        if on_destroy
          results = on_destroy.call(attributes: attributes, target_keys: target_keys)
        else
          results = model.destroy(target_attributes)
          return if results.empty?
          raise TableSync::DestroyError.new(target_attributes) if results.size != 1
        end

        @config.inside_transaction_after.each { |block| block.call(destroy_data) }

        @config.model.after_commit do
          @config.callback_registry.get_callbacks(kind: :after_commit, event: :destroy).each do |cb|
            cb[results]
          end
        end
      end
    end

    def with_wrapping(data = {}, &block)
      if @config.wrap_receiving
        @config.wrap_receiving.call(data, block)
      else
        yield
      end
    end

    def expected_update_result?(query_results)
      query_results.uniq { |d| d.slice(*target_keys) }.size == query_results.size
    end

    def prevent_incomplete_event!(attributes)
      unless target_keys.all?(&attributes.keys.method(:include?))
        raise TableSync::UnprovidedEventTargetKeysError.new(target_keys, attributes)
      end
    end
  end
end
