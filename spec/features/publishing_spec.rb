# frozen_string_literal: true

class TestUser
  class << self
    def find_by(*)
      # Stub
    end

    def lock(*)
      # Stub
      self
    end

    def primary_key
      "id"
    end

    def table_name
      :test_users
    end
  end
end

class TestUserWithCustomStuff < TestUser
  class << self
    def table_sync_model_name
      "SomeFancyName"
    end

    def table_sync_destroy_attributes(attrs)
      {
        id: attrs[:id],
        mail_address: attrs[:email],
      }
    end
  end
end

TestJob = Class.new(ActiveJob::Base)

RSpec.describe TableSync::Publisher do
  let(:id)            { 1 }
  let(:email)         { "example@example.org" }
  let(:attributes)    { { "id" => id, "email" => email } }
  let!(:pk)           { "id" }
  let(:debounce_time) { nil }

  before { Timecop.freeze("2010-01-01 12:00 UTC") }

  def aj_keys
    RUBY_VERSION >= "2.7" && Rails.version >= "6.0.3" ? "_aj_ruby2_keywords" : "_aj_symbol_keys"
  end

  describe "#publish" do
    def publish
      described_class.new(
        "TestUser", attributes, state: state, debounce_time: debounce_time
      ).publish
    end

    def assert_last_job(time)
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.last

      object_attributes = attributes.merge("_aj_symbol_keys" => attributes.keys)
      job_params = {
        "state" => state.to_s,
        "confirm" => true,
        aj_keys => %w[state confirm],
      }

      expect(job[:job]).to eq(TestJob)
      expect(job[:args]).to eq(["TestUser", object_attributes, job_params])
      expect(job[:at]).to eq(time.to_i)
    end

    before { TableSync.publishing_job_class_callable = -> { TestJob } }

    context "destroying" do
      let(:state) { :destroyed }

      it "enqueues job immediately" do
        expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
        expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
        assert_last_job(Time.now)
      end
    end

    context "updating" do
      let(:state) { :updated }

      it "debounces" do
        publish
        assert_last_job(Time.now)

        Timecop.travel(40.seconds)
        expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
        assert_last_job(20.seconds.from_now)

        expect { publish }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }
        Timecop.travel(30.seconds)

        expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
        assert_last_job(50.seconds.from_now)
      end

      context "when skip_debounce is set" do
        let(:debounce_time) { 25 }

        specify do
          publish
          assert_last_job(Time.now)

          Timecop.travel(10.seconds)
          expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
          assert_last_job(15.seconds.from_now)

          expect { publish }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }
          Timecop.travel(25.seconds)

          expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
          assert_last_job(15.seconds.from_now)
        end

        context "enqueues job immediately" do
          let(:debounce_time) { 0 }

          specify do
            expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
            expect { publish }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
            assert_last_job(Time.now)
          end
        end
      end
    end

    context "composite keys" do
      let(:state) { :updated }
      let(:pk) { %w[id project_id] }

      it "works" do
        publish
        assert_last_job(Time.now)
      end
    end
  end

  describe "#publish_now" do
    def publish
      described_class.new(class_name, attributes, state: state).publish_now
    end

    def expect_message(event, attributes, created:)
      args = {
        routing_key: routing_key,
        event: :table_sync,
        confirm_select: true,
        realtime: true,
        headers: headers,
        data: {
          event: event,
          model: expected_model_name,
          attributes: attributes,
          version: Time.now.to_f,
          metadata: { created: created },
        },
      }

      expect_rabbit_message(args)
    end

    let(:user)                { double(:user) }
    let(:class_name)          { "TestUser" }
    let(:expected_model_name) { "TestUser" }
    let(:routing_key)         { "#{class_name}-#{email}" }
    let(:headers)             { { class_name => email } }

    let(:routing_key_callable) { -> (klass, attrs) { "#{klass}-#{attrs[:email]}" } }
    let(:metadata_callable)    { -> (klass, attrs) { { klass => attrs[:email] } } }

    before do
      [TestUser, TestUserWithCustomStuff].each do |klass|
        allow(klass).to receive(:find_by).with(id: id).and_return(user)
      end

      TableSync.routing_key_callable = routing_key_callable
      TableSync.routing_metadata_callable = metadata_callable
    end

    context "destroyed" do
      let(:state) { :destroyed }

      it "publishes" do
        expect_message(:destroy, { id: id }, created: false)
        publish
      end

      context "class with custom destroy attributes" do
        let(:class_name) { "TestUserWithCustomStuff" }
        let(:expected_model_name) { "SomeFancyName" }

        it "uses that attributes" do
          expect_message(:destroy, { id: id, mail_address: "example@example.org" }, created: false)
          publish
        end
      end
    end

    context "unknown state" do
      let(:state) { :unknown }

      specify { expect { publish }.to raise_error("Unknown state: :unknown") }
    end

    context "not destroyed" do
      let(:state) { :created }

      context "does not respond #attributes_for_sync" do
        before do
          allow(user).to receive(:attributes).and_return("db_attribute" => "db_value")
        end

        it "publishes" do
          expect_message(:update, { "db_attribute" => "db_value" }, created: true)
          publish
        end
      end

      context "override methods" do
        let(:default_attributes)  { { id: id } }
        let(:expected_attributes) { default_attributes }

        let(:override_methods) do
          %i[attributes_for_sync attrs_for_metadata attrs_for_routing_key]
        end

        before do
          override_methods.each do |m|
            allow(TestUser).to receive(:method_defined?).with(m).and_return(false)
          end

          allow(user).to receive(:attributes).and_return(default_attributes)
        end

        shared_examples "responds_to" do |override_method|
          before do
            allow(TestUser).to receive(:method_defined?).with(override_method).and_return(true)

            allow(user).to receive(override_method).and_return(override_data)
          end

          it "overrides default" do
            expect_message(:update, expected_attributes, created: true)
            publish
          end
        end

        context "attributes_for_sync" do
          let(:override_data)       { { "custom_attribute" => "custom_value" } }
          let(:expected_attributes) { override_data }

          include_examples "responds_to", :attributes_for_sync
        end

        context "attrs_for_metadata" do
          let(:override_data)     { { "custom_header" => "some_header" } }
          let(:headers)           { override_data }
          let(:metadata_callable) { -> (_klass, attrs) { attrs } }

          include_examples "responds_to", :attrs_for_metadata
        end

        context "attrs_for_routing_key" do
          let(:override_data) { { "custom_key" => "custom_attr" } }
          let(:routing_key)   { "TestUser-custom_attr" }

          let(:routing_key_callable) do
            -> (klass, attrs) { "#{klass}-#{attrs["custom_key"]}" }
          end

          include_examples "responds_to", :attrs_for_routing_key
        end
      end
    end
  end
end
