# frozen_string_literal: true

# @api private
# @since 2.2.0
class TableSync::Plugins::Abstract
  class << self
    # @param child_klass [Class]
    # @return [void]
    #
    # @api private
    # @since 2.2.0
    def inherited(child_klass)
      child_klass.instance_variable_set(:@__loaded__, false)
      child_klass.instance_variable_set(:@__lock__, Mutex.new)
      super
    end

    # @return [void]
    #
    # @api private
    # @since 2.2.0
    def load!
      __thread_safe__ do
        unless @__loaded__
          @__loaded__ = true
          install!
        end
      end
    end

    # @return [Boolean]
    #
    # @api private
    # @since 2.2.0
    def loaded?
      __thread_safe__ { @__loaded__ }
    end

    private

    # @return [void]
    #
    # @api private
    # @since 2.2.0
    def install!; end

    # @return [Any]
    #
    # @api private
    # @since 2.2.0
    def __thread_safe__
      @__lock__.synchronize { yield }
    end
  end
end
