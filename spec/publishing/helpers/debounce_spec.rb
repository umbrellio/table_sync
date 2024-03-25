# frozen_string_literal: true

describe TableSync::Publishing::Helpers::Debounce do
  let(:params) do
    {
      object_class: "SequelUser",
      needle: { id: 1 },
      debounce_time: debounce_time,
      event: event,
    }
  end

  let(:service)       { described_class.new(**params) }
  let(:debounce_time) { 30 }
  let(:event)         { :update }
  let(:current_time)  { Time.current.beginning_of_day }

  before { Timecop.freeze(current_time) }

  shared_examples "returns correct next_sync_time" do
    it "next_sync_time returns correct value" do
      expect(service.next_sync_time).to eq(expected_time)
    end
  end

  shared_examples "skip? returns" do |value|
    context "skip? is #{value}" do
      it value do
        expect(service.skip?).to eq(value)
      end
    end
  end

  def set_cached_sync_time(time)
    Rails.cache.write(service.cache_key, time)
  end

  context "debounce time -> nil" do
    let(:debounce_time) { nil }

    it "defaults debounce to 60" do
      expect(service.debounce_time).to eq(60)
    end
  end

  context "case0: debounce time -> zero" do
    let(:debounce_time) { 0 }
    let(:expected_time) { current_time }

    include_examples "skip? returns", false
    include_examples "returns correct next_sync_time"
  end

  context "case 1: cached sync time is empty" do
    let(:expected_time) { current_time }

    include_examples "skip? returns", false
    include_examples "returns correct next_sync_time"
  end

  context "case 2: cached sync time in the past" do
    context "case 2.1: debounce time passed" do
      let(:expected_time) { current_time }
      let(:cached_time)   { current_time - 30.seconds }

      context "cache existed" do
        before { set_cached_sync_time(cached_time) }

        include_examples "skip? returns", false
        include_examples "returns correct next_sync_time"
      end

      context "cache expired" do
        include_examples "skip? returns", false
        include_examples "returns correct next_sync_time"
      end
    end

    context "case 2.2: debounce time not passed yet" do
      let(:expected_time) { cached_time + 30.seconds }
      let(:cached_time)   { current_time }

      before { set_cached_sync_time(cached_time) }

      include_examples "skip? returns", false
      include_examples "returns correct next_sync_time"
    end
  end

  context "case 3: cached sync time in the future" do
    let(:cached_time) { current_time + 10.seconds }

    before { set_cached_sync_time(cached_time) }

    context "case 3.1: event update" do
      let(:expected_time) { nil }

      include_examples "skip? returns", true
      include_examples "returns correct next_sync_time"
    end

    context "case 3.2: event destroy" do
      let(:event)         { :destroy }
      let(:expected_time) { cached_time + 30.seconds }

      include_examples "skip? returns", false
      include_examples "returns correct next_sync_time"
    end
  end
end
