# frozen_string_literal: true

class TableSync::Publishing::Params::Base
  include Tainbox

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

  # EXCHANGE

  # only set if exists in original, what if simply nil?
  def exchange_name
    TableSync.exchange_name
  end

  # ROUTING KEY

  def calculated_routing_key
    if TableSync.routing_key_callable
      TableSync.routing_key_callable.call(klass, attrs_for_routing_key)
    else
      raise "Can't publish, set TableSync.routing_key_callable!"
    end
  end

  # HEADERS

  def calculated_headers
    if TableSync.headers_callable
      TableSync.headers_callable.call(klass, attrs_for_routing_key)
    else
      raise "Can't publish, set TableSync.headers_callable!"
    end
  end

  # NOT IMPLEMENTED

  # name of the model being synced in the string format
  def klass
    raise NotImplementedError
  end

  def routing_key
    raise NotImplementedError
  end

  def headers
    raise NotImplementedError
  end

  def attrs_for_routing_key
    raise NotImplementedError
  end

  def attrs_for_headers
    raise NotImplementedError
  end
end
