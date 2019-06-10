# frozen_string_literal: true

class << Rails
  def root
    Pathname.new(__dir__).join("..", "..")
  end
end
