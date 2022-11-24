# frozen_string_literal: true

describe TableSync::Instrument do
  def run!
    described_class.notify(**notify_args)
  end

  let(:notifier) { double(:notifier) }
  let(:notify_args) { notify_keys.to_h { |x| [x, Object.new] } }
  let(:notify_keys) { %i[table schema event count direction] }

  before { TableSync.notifier = notifier }

  it "sent notification" do
    expect(notifier).to receive(:notify).once

    run!
  end

  context "with disabled notification" do
    before { TableSync.notify = false }

    it "doesn't send notification" do
      expect(notifier).not_to receive(:notify)

      run!
    end
  end

  context "with missing kwargs" do
    let(:notify_keys) { %i[table schema event] }

    it "raises ArgumentError" do
      expect { run! }.to raise_error do |e|
        expect(e).to be_an_instance_of(ArgumentError)
        expect(e.message).to eq("Missing keywords: count, direction.")
      end
    end
  end

  context "when notifier is not set" do
    before { TableSync.notifier = nil }

    it "raises InvalidConfig error" do
      expect { run! }.to raise_error(TableSync::InvalidConfig)
    end
  end
end
