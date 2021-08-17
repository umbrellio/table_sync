# frozen_string_literal: true

describe TableSync::Setup::ActiveRecord do
  include_context "with created users", 1

  let(:job) { double("Job", perform_at: 1) }

  before do
    TableSync.single_publishing_job_class_callable = -> { job }

    stub_const("TestARUser", Class.new(ARecordUser))
  end

  def setup_sync(options = {})
    TestARUser.instance_exec { TableSync.sync(self, **options) }
  end

  include_examples "setup: enqueue job behaviour", "TestARUser"

  context "setup" do
    it "sends after_commit for all events" do
      expect(TestARUser).to receive(:after_commit).with(on: :create)
      expect(TestARUser).to receive(:after_commit).with(on: :update)
      expect(TestARUser).to receive(:after_commit).with(on: :destroy)

      setup_sync
    end
  end
end
