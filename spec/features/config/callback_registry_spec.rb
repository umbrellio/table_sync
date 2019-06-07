# frozen_string_literal: true

RSpec.describe TableSync::Config::CallbackRegistry do
  CALLBACK_KINDS = %i[after_commit before_commit].freeze
  EVENTS = %i[create update destroy].freeze

  let(:instance) { described_class.new }

  CALLBACK_KINDS.each do |callback_kind|
    context "callback kind: #{callback_kind}" do
      EVENTS.each do |event|
        context "event: #{event}" do
          it "is empty by default" do
            expect(instance.get_callbacks(kind: callback_kind, event: event)).to eq([])
          end

          it "registers and returns callbacks" do
            kek_proc = proc { "kek" }
            instance.register_callback(kek_proc, kind: callback_kind, event: event)
            expect(instance.get_callbacks(kind: callback_kind, event: event))
              .to contain_exactly(kek_proc)

            pek_proc = proc { "pek" }
            instance.register_callback(pek_proc, kind: callback_kind, event: event)
            expect(instance.get_callbacks(kind: callback_kind, event: event))
              .to contain_exactly(kek_proc, pek_proc)
          end
        end
      end
    end
  end

  context "invalid arguments" do
    let(:callback) { proc {} }

    context "invalid callback kind" do
      it "fails to register callback" do
        expect { instance.register_callback(callback, kind: :during_commit, event: :update) }
          .to raise_error(
            described_class::InvalidCallbackKindError,
            "Invalid callback kind: :during_commit. "\
            "Valid kinds are [:after_commit, :before_commit]",
          )
      end

      it "fails to retrieve callbacks" do
        expect { instance.get_callbacks(kind: :during_commit, event: :update) }
          .to raise_error(
            described_class::InvalidCallbackKindError,
            "Invalid callback kind: :during_commit. "\
            "Valid kinds are [:after_commit, :before_commit]",
          )
      end
    end

    context "invalid event" do
      it "fails to register callback" do
        expect { instance.register_callback(callback, kind: :after_commit, event: :procrastinate) }
          .to raise_error(
            described_class::InvalidEventError,
            "Invalid event: :procrastinate. Valid events are [:create, :update, :destroy]",
          )
      end

      it "fails to retrieve callbacks" do
        expect { instance.get_callbacks(kind: :after_commit, event: :procrastinate) }
          .to raise_error(
            described_class::InvalidEventError,
            "Invalid event: :procrastinate. Valid events are [:create, :update, :destroy]",
          )
      end
    end
  end
end
