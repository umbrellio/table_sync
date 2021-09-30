# frozen_string_literal: true

describe TableSync do
  context "invalid ORM" do
    it "raises error" do
      expect { TableSync.orm = :incorrect_orm }.to raise_error(TableSync::ORMNotSupported)
    end
  end
end
