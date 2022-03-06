# frozen_string_literal: true

describe TableSync do
  context "invalid ORM" do
    it "raises error" do
      expect { TableSync.orm = :incorrect_orm }.to raise_error(TableSync::ORMNotSupported)
    end
  end

  context "when notify is not set" do
    it "properly calculates boolean method" do
      expect(TableSync.notify?).to eq(false)
    end

    context "when notifier is set" do
      before { TableSync.notifier = Object.new }

      it "sets notify to true" do
        expect(TableSync.notify?).to eq(true)
      end
    end
  end
end
