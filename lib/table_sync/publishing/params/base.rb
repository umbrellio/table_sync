# frozen_string_literal: true

module TableSync::Publishing::Params
  class Base
    DEFAULT_PARAMS = {
      confirm_select: true,
      realtime:       true,
      event:         :table_sync,
    }.freeze

    def construct
      DEFAULT_PARAMS.merge(
        routing_key:   routing_key, 
        headers:       headers,
        exchange_name: exchange_name,
      )
    end

    private

    # ROUTING KEY

    def calculated_routing_key
      if TableSync.routing_key_callable
        TableSync.routing_key_callable.call(object_class, attrs_for_routing_key)
      else
        raise "Can't publish, set TableSync.routing_key_callable!"
      end
    end

    def attrs_for_routing_key
      {}
    end

    # HEADERS

    def calculated_headers
      if TableSync.headers_callable
        TableSync.headers_callable.call(object_class, attrs_for_headers)
      else
        raise "Can't publish, set TableSync.headers_callable!"
      end
    end

    def attrs_for_headers
      {}
    end

    # NOT IMPLEMENTED

    # name of the model being synced in the string format
    def object_class
      raise NotImplementedError
    end

    def routing_key
      raise NotImplementedError
    end

    def headers
      raise NotImplementedError
    end

    def exchange_name
      raise NotImplementedError
    end
  end
end