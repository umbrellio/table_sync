# frozen_string_literal: true

class TableSync::EventActions::DataWrapping::Update < TableSync::EventActions::DataWrapping::Base
  def type
    :update
  end

  def each
    event_data.each_pair do |model_klass, changed_models_attrs|
      yield([model_klass, changed_models_attrs])
    end
  end

  def destroy?
    false
  end

  def update?
    true
  end
end
