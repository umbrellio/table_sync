# frozen_string_literal: true

class TestUser
  class << self
    def find_by(*)
      # Stub
    end

    def lock(*)
      # Stub
      self
    end

    def primary_key
      "id"
    end

    def table_name
      :test_users
    end
  end
end

class TestUserWithCustomStuff < TestUser
  class << self
    def table_sync_model_name
      "SomeFancyName"
    end

    def table_sync_destroy_attributes(attrs)
      {
        id: attrs[:id],
        mail_address: attrs[:email],
      }
    end
  end
end

TestJob = Class.new(ActiveJob::Base)
