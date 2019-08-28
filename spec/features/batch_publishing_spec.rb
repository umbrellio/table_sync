# frozen_string_literal: true

describe TableSync::BatchPublisher do
  let(:pk)         { "id" }
  let(:id)         { 1 }
  let(:email)      { "example@example.org" }
  let(:attributes) { [{ "id" => id, "email" => email }] }
  let(:options)    { {} }
  let(:model_name) { "TestUser" }
  let(:publisher)  { described_class.new(model_name, attributes, options) }

  let(:push_original_attributes) { false }

  before { Timecop.freeze("2018-01-01 12:00 UTC") }

  before { TableSync.batch_publishing_job_class_callable = -> { TestJob } }

  def assert_last_job
    job = ActiveJob::Base.queue_adapter.enqueued_jobs.last

    object_attributes = attributes.map { |attrs| attrs.merge("_aj_symbol_keys" => attrs.keys) }
    job_params = {
      "confirm" => true,
      "_aj_symbol_keys" => %w[confirm push_original_attributes],
      "push_original_attributes" => push_original_attributes,
    }

    expect(job[:job]).to eq(TestJob)
    expect(job[:args]).to eq(["TestUser", object_attributes, job_params])
    expect(job[:at]).to be_nil
  end

  def expect_message(attributes, model_name = "TestUser", routing_key = "TestUser")
    expect_rabbit_message(
      routing_key: routing_key,
      event: :table_sync,
      confirm_select: true,
      realtime: true,
      headers: nil,
      data: {
        event: :update,
        model: model_name,
        attributes: attributes,
        version: Time.now.to_f,
        metadata: {},
      },
    )
  end

  context "#publish" do
    before { TableSync.routing_key_callable = -> (klass, _) { klass } }

    context "updating" do
      it "performs" do
        publisher.publish
        assert_last_job
      end
    end

    context "composite keys" do
      let(:pk) { %w[id project_id] }

      it "performs" do
        publisher.publish
        assert_last_job
      end
    end

    context "with inserting array at attributes" do
      let(:attributes) { ["example_array" => [1, 2, 3]] }

      it "doesn't exclude this array from original attributes" do
        publisher.publish
        assert_last_job
      end
    end

    context "with not serialized original attributes" do
      let(:attributes) do
        [
          good_attribute: { kek: "pek", array_with_nil: [nil] },
          half_bad: { bad_inside: [Time.current, Float::INFINITY], good_inside: 1 },
          Time.current => "wtf?!",
        ]
      end

      it "filters attributes with wrong types" do
        publisher.publish
        job = ActiveJob::Base.queue_adapter.enqueued_jobs.last

        params = job[:args][1]
        expect(params.first.keys.size).to eq(3)
        expect(params.first["good_attribute"]).to include("kek" => "pek", "array_with_nil" => [nil])
        expect(params.first["half_bad"]).to include("bad_inside" => [], "good_inside" => 1)
      end
    end

    # NOTE: for compatibility with active_job 4.2.11
    context "attributes with symbolic values in hashes" do
      let(:attributes) do
        [
          half_bad: { bad_inside: { foo: :bar }, good_inside: { foo: "bar" } },
        ]
      end

      it "converts these values to string" do
        publisher.publish
        job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        params = job[:args][1]
        expect(params.first.keys.size).to eq(2)
        expect(params.first["half_bad"]).to include(
          "bad_inside" => { "_aj_symbol_keys" => ["foo"], "foo" => "bar" },
          "good_inside" => { "_aj_symbol_keys" => ["foo"], "foo" => "bar" },
        )
      end
    end

    context "with inserting original attributes" do
      let(:push_original_attributes) { true }
      let(:options) { Hash[push_original_attributes: true] }

      it "publish job with this option, setted to true" do
        publisher.publish
        assert_last_job
      end
    end
  end

  context "#publish_now" do
    let(:user) { double(:user) }

    before do
      allow(TestUser).to receive(:find_by).with(id: id).and_return(user)
      TableSync.routing_key_callable = -> (klass, _) { klass }
    end

    context "with overriden_routing_key" do
      let(:custom_key)     { "CustomKey" }
      let(:options)        { { routing_key: custom_key } }
      let(:expected_attrs) { [{ "test_attr" => "test_value" }] }

      before do
        allow(user).to receive(:attributes).and_return(expected_attrs.first)
      end

      it "has correct routing key" do
        expect_message(expected_attrs, "TestUser", custom_key)
        publisher.publish_now
      end
    end

    context "updated (alias for not destroyed)" do
      context "doesn't respond to #attributes_for_sync" do
        before do
          allow(user).to receive(:attributes).and_return("test_attr" => "test_value")
        end

        it "publishes" do
          expect_message(["test_attr" => "test_value"])
          publisher.publish_now
        end
      end
    end

    context "responds to #attributes_for_sync" do
      before do
        allow(TestUser).to receive(:method_defined?).with(:attributes_for_sync).and_return(true)

        allow(user).to receive(:attributes_for_sync)
                           .and_return("the_ultimate_question_of_live_and_everything" => 42)
      end

      it "publishes" do
        expect_message(["the_ultimate_question_of_live_and_everything" => 42])
        publisher.publish_now
      end
    end

    context "doesn't find any object with that pk" do
      before do
        allow(TestUser).to receive(:find_by).with(id: id).and_return(nil)
      end

      it "doesn't publish" do
        expect_no_rabbit_messages
        publisher.publish_now
      end
    end

    context "responds to #table_sync_model_name" do
      let(:model_name) { "TestUserWithCustomStuff" }

      before do
        allow(user).to receive(:attributes).and_return("test_attr" => "test_value")
        TableSync.routing_key_callable = -> (*_) { "TestUser" }
      end

      it "publishes" do
        expect_message(["test_attr" => "test_value"], "SomeFancyName")
        publisher.publish_now
      end
    end

    context "inserts original attributes" do
      before do
        allow(user).to receive(:attributes).and_return("kek" => "pek")
      end

      let(:options) { Hash[push_original_attributes: true] }

      it "sends original attributes array instead of record attributes" do
        expect_message([id: 1, email: "example@example.org"])
        publisher.publish_now
      end
    end
  end
end
