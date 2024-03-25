# frozen_string_literal: true

module Rails
  def self.cache
    @cache ||= Class.new do
      def read(key)
        store[key]
      end

      def write(key, value, _options = nil)
        store[key] = value
      end

      def clear
        @store = {}
      end

      def store
        @store ||= {}
      end
    end.new
  end
end

RSpec.configure { |config| config.before { Rails.cache.clear } }
