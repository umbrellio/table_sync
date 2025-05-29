# frozen_string_literal: true

class TableSync::Utils::ProcArray < Proc
  def initialize(&)
    @array = []
    super
  end

  def push(&block)
    @array.push(block)
    self
  end

  def call(*args, &)
    super(@array, args, &)
  end
end
