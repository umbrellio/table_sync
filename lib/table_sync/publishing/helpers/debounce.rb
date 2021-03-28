# frozen_string_literal: true

module TableSync::Publishing::Helpers
  class Debounce
  	include Memery

    attr_reader :debounce_time, :object_class, :needle

    def initialize(object_class:, needle:, debounce_time: nil)
      @debounce_time = debounce_time
      @object_class  = object_class
      @needle        = needle
    end

    def sync_time?
    	no_last_sync_time? || past_next_sync_time?
    end

    # No sync before, no need for debounce
    def no_last_sync_time?
    	last_sync_time.nil?
    end

    def past_next_sync_time?

    end

    memoize def last_sync_time
    	Rails.cache.read(cache_key)
    end

    memoize def current_time
    	Time.current
    end

    def save_next_sync_time(time)
    	Rails.cache.write(cache_key, next_sync_time)
    end

    def cache_key
    	"#{object_class}/#{needle.values.join}_table_sync_time".delete(" ")
    end
  end
end

  # def publish
  #   return enqueue_job if destroyed? || debounce_time.zero?

  #   sync_time = Rails.cache.read(cache_key) || current_time - debounce_time - 1.second
  #   return if sync_time > current_time

  #   next_sync_time = sync_time + debounce_time
  #   next_sync_time <= current_time ? enqueue_job : enqueue_job(next_sync_time)
  # end

  # def enqueue_job(perform_at = current_time)
  #   job = job_class.set(wait_until: perform_at)
  #   job.perform_later(object_class.name, original_attributes, state: state.to_s, confirm: confirm?)
  #   Rails.cache.write(cache_key, perform_at)
  # end
