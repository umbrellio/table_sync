# frozen_string_literal: true

# CASES FOR DEBOUNCE

# Cached Sync Time -> CST - time last sync has occured or next sync will occur
# Next Sync Time   -> NST - time next sync will occur

# 0
# Condition: debounce_time is zero.
# No debounce, sync right now.
# Result: NST -> Time.current

# 1
# Condition: CST is empty.
# There was no sync before. Can be synced right now.
# Result: NST -> Time.current

# 2
# Condition: CST =< Time.current.
# There was a sync before.

# 2.1
# Subcondition: CST + debounce_time <= Time.current
# Enough time passed for debounce condition to be satisfied.
# No need to wait. Can by synced right now.
# Result: NST -> Time.current

# 2.2
# Subcondition: CST + debounce_time > Time.current
# Debounce condition is not satisfied. Must wait till debounce period has passed.
# Will be synced after debounce period has passed.
# Result: NST -> CST + debounce_time

# 3
# Condition: CST > Time.current
# Sync job has already been enqueued in the future.

# 3.1
# Subcondition: event -> update | create
# No need to sync upsert event, since it has already enqueued sync in the future.
# It will sync fresh version anyway.
# NST -> Skip, no sync.

# 3.2
# Subcondition: event -> destroy
# In this case the already enqueued job must be upsert.
# Thus destructive sync has to send message after upsert sync.
# NST -> CST + debounce_time

module TableSync::Publishing::Helpers
  class Debounce
    include Memery

    DEFAULT_TIME = 60

    attr_reader :debounce_time, :object_class, :needle, :event

    def initialize(object_class:, needle:, event:, debounce_time: nil)
      @event         = event
      @debounce_time = debounce_time || DEFAULT_TIME
      @object_class  = object_class
      @needle        = needle
    end

    def skip?
      sync_in_the_future? && upsert_event? # case 3.1
    end

    memoize def next_sync_time
      return current_time        if debounce_time.zero? # case 0
      return current_time        if no_sync_before?     # case 1

      return current_time        if sync_in_the_past? && debounce_time_passed?     # case 2.1
      return debounced_sync_time if sync_in_the_past? && debounce_time_not_passed? # case 2.2

      return debounced_sync_time if sync_in_the_future? && destroy_event? # case 3.2
    end

    # CASE 1
    def no_sync_before?
      cached_sync_time.nil?
    end

    # CASE 2
    def sync_in_the_past?
      cached_sync_time <= current_time
    end

    def debounce_time_passed?
      cached_sync_time + debounce_time.seconds <= current_time
    end

    def debounce_time_not_passed?
      cached_sync_time + debounce_time.seconds > current_time
    end

    # CASE 3
    def sync_in_the_future?
      !!cached_sync_time && (cached_sync_time > current_time)
    end

    def destroy_event?
      event == :destroy
    end

    def upsert_event?
      !destroy_event?
    end

    # MISC

    def debounced_sync_time
      cached_sync_time + debounce_time.seconds
    end

    memoize def current_time
      Time.current
    end

    # CACHE

    memoize def cached_sync_time
      Rails.cache.read(cache_key)
    end

    def cache_next_sync_time
      Rails.cache.write(
        cache_key,
        next_sync_time,
        expires_at: next_sync_time + debounce_time.seconds,
      )
    end

    def cache_key
      "#{object_class}/#{needle.values.join}_table_sync_time".delete(" ")
    end
  end
end
