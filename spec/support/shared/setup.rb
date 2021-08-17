# frozen_string_literal: true

shared_examples "setup: enqueue job behaviour" do |test_class_name|
  let(:test_class) { test_class_name.constantize }

  shared_examples "enqueues job" do
    specify do
      expect(job).to receive(:perform_at)
      test_class.first.update(name: "new_name")
    end
  end

  shared_examples "doesn't enqueue job" do
    specify do
      expect(job).not_to receive(:perform_at)
      test_class.first.update(name: "new_name")
    end
  end

  context "without options" do
    before { setup_sync }

    include_examples "enqueues job"
  end

  context "if option" do
    context "true" do
      before { setup_sync(if: -> (_) { true }) }

      include_examples "enqueues job"
    end

    context "false" do
      before { setup_sync(if: -> (_) { false }) }

      include_examples "doesn't enqueue job"
    end
  end

  context "unless option" do
    context "false" do
      before { setup_sync(unless: -> (_) { false }) }

      include_examples "enqueues job"
    end

    context "true" do
      before { setup_sync(unless: -> (_) { true }) }

      include_examples "doesn't enqueue job"
    end
  end

  context "both options" do
    context "skips by if (false)" do
      before { setup_sync(if: -> (_) { false }, unless: -> (_) { false }) }

      include_examples "doesn't enqueue job"
    end

    context "skips by unless (true)" do
      before { setup_sync(if: -> (_) { true }, unless: -> (_) { true }) }

      include_examples "doesn't enqueue job"
    end
  end
end
