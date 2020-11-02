# frozen_string_literal: true

# Ruby does not support interfaces, and there is no way to implement them.
# Interfaces check a methods of a class after the initialization of the class is complete.
# But in Ruby, the initialization of a class cannot be completed.
# In execution time we can open any class and add some methods (monkey patching).
# Ruby has `define_method`, singleton methods, etc.
#
# Duck typing is a necessary measure, the only one available in the Ruby architecture.
#
# Interfaces can be implemented in particular cases with tests for example.
# But this is not suitable for gems that are used by third-party code.
#
# So, we still want to check interfaces and have a nice error messages,
# even if it will be duck typing.
#
# Next code do this.

class TableSync::Utils::InterfaceChecker
  INTERFACES = SelfData.load

  attr_reader :object

  def initialize(object)
    @object = object
  end

  def implements(interface_name)
    INTERFACES[interface_name].each do |method_name, options|
      unless object.respond_to?(method_name)
        raise_error(method_name, options)
      end

      unless include?(object.method(method_name).parameters, options[:parameters])
        raise_error(method_name, options)
      end
    end
    self
  end

  private

  def include?(checked, expected)
    (filter(expected) - filter(checked)).empty?
  end

  def raise_error(method_name, options)
    raise TableSync::InterfaceError.new(
      object,
      method_name,
      options[:parameters],
      options[:description],
    )
  end

  def filter(parameters)
    # for req and block parameters types we can ignore names
    parameters.map { |param| %i[req block].include?(param.first) ? [param.first] : param }
  end
end

__END__
:receiving_model:
  :upsert:
    :parameters:
      - - :keyreq
        - :data
      - - :keyreq
        - :target_keys
      - - :keyreq
        - :version_key
      - - :keyreq
        - :default_values
    :description: "returns an array with updated rows"
  :columns:
    :parameters: []
    :description: "returns all table columns"
  :destroy:
    :parameters:
      - - :keyreq
        - :data
      - - :keyreq
        - :target_keys
    :description: "returns an array with destroyed rows"
  :transaction:
    :parameters:
      - - :block
        - :block
    :description: "implements the database transaction"
  :after_commit:
    :parameters:
      - - :block
        - :block
    :description: "executes the block after committing the transaction"
  :primary_keys:
    :parameters: []
    :description: "returns an array with the primary_keys"
  :table:
    :parameters: []
    :description: "returns an instance of Symbol"
  :schema:
    :parameters: []
    :description: "returns an instance of Symbol"