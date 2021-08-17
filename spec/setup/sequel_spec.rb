# frozen_string_literal: true

describe TableSync::Setup::Sequel do
  include_context "with Sequel ORM"
  include_context "with created users", 1

  let(:job) { double("Job", perform_at: 1) }

  before do
    TableSync.single_publishing_job_class_callable = -> { job }

    stub_const("TestSequelUser", Class.new(SequelUser))
  end

  def setup_sync(options = {})
    TestSequelUser.instance_exec { TableSync.sync(self, **options) }
  end

  include_examples "setup: enqueue job behaviour", "TestSequelUser"

  context "setup" do
    it "sends define_method for all events" do
      expect(TestSequelUser).to receive(:define_method).with(:after_create)
      expect(TestSequelUser).to receive(:define_method).with(:after_update)
      expect(TestSequelUser).to receive(:define_method).with(:after_destroy)

      setup_sync
    end
  end
end
