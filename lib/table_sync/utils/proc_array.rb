# frozen_string_literal: true

class TableSync::Utils::ProcArray < Proc
  def initialize(&block)
    @array = []
    super(&block)
  end

  def push(&block)
    @array.push(block)
    self
  end

  def call(*args, &block)
    super(@array, args, &block)
  end
end
