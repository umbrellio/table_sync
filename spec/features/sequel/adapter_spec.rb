# frozen_string_literal: true

TableSync.orm = :sequel

class ItemWithoutPredicate < Sequel::Model(:items)
  TableSync.sync(self)
end

class ItemWithPositivePredicate < Sequel::Model(:items)
  TableSync.sync(self, if: -> (*) { true })
end

class ItemWithNegativePredicate < Sequel::Model(:items)
  TableSync.sync(self, if: -> (*) { false })
end

class ItemWithBothPredicates < Sequel::Model(:items)
  TableSync.sync(self, if: -> (*) { if_expr }, unless: -> (*) { unless_expr })

  attr_accessor :if_expr
  attr_accessor :unless_expr
end

TableSync.orm = :active_record

RSpec.describe TableSync::ORMAdapter::Sequel, :sequel do
  let(:itemClass) { ItemWithoutPredicate }
  let(:attrs) { { name: "An item", price: 10 } }
  let(:queue_adapter) { ActiveJob::Base.queue_adapter }
  let(:opts) { {} }
  let!(:item) { itemClass.create(attrs) }

  def create
    itemClass.create(attrs)
  end

  def update
    item.update(price: 20)
  end

  def destroy
    item.destroy
  end

  def enqueues(&block)
    expect(block).to change(queue_adapter.enqueued_jobs, :count).by(1)
  end

  def ignores(&block)
    expect(block).not_to change(queue_adapter.enqueued_jobs, :count)
  end

  context "without predicate" do
    it { enqueues { create } }
    it { enqueues { update } }
    it { enqueues { destroy } }
  end

  context "with positive predicate" do
    let(:itemClass) { ItemWithPositivePredicate }

    it { enqueues { create } }
    it { enqueues { update } }
    it { enqueues { destroy } }
  end

  context "with negative predicate" do
    let(:itemClass) { ItemWithNegativePredicate }

    it { ignores { create } }
    it { ignores { update } }
    it("also enqueues after destroy") { enqueues { destroy } }
  end

  context "with both predicates" do
    let(:itemClass) { ItemWithBothPredicates }

    let(:if_expr) { true }
    let(:unless_expr) { true }

    before do
      item.if_expr     = if_expr
      item.unless_expr = unless_expr
    end

    context "positive" do
      let(:if_expr) { true }
      let(:unless_expr) { false }

      it { enqueues { update } }
    end

    context "conflicts" do
      let(:if_expr) { true }
      let(:unless_expr) { true }

      it { ignores { update } }
    end

    context "negative" do
      let(:if_expr) { false }
      let(:unless_expr) { true }

      it { ignores { update } }
    end
  end
end
