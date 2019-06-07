# frozen_string_literals: true

class << Rails
  def root
    Pathname.new(__dir__).join("..", "..")
  end
end
