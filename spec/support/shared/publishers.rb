# frozen_string_literal: true

# needs let(:attributes)
shared_examples "publisher#publish_now with stubbed message" do |message_class|
  describe "#publish_now" do
    context "with stubbed message" do
      let(:event) { :update }
      let(:message_double) { double("Message") }

      before do
        allow(message_class).to receive(:new).and_return(message_double)
        allow(message_double).to receive(:publish)
        allow(message_double).to receive(:empty?).and_return(false)
      end

      it "initializes message with correct parameters" do
        expect(message_class).to receive(:new).with(attributes)
        expect(message_double).to receive(:publish)

        described_class.new(attributes).publish_now
      end
    end
  end
end

# needs let(:attributes)
# needs let(:object_class) - String
# needs let(:expected_object_data)
# needs let(:headers)
# needs let(:routing_key)
shared_examples "publisher#publish_now without stubbed message" do
  describe "#publish_now" do
    context "without stubbed message" do
      let(:rabbit_params) do
        a_hash_including(
          data: a_hash_including(
            attributes: expected_object_data,
            event:,
            metadata: { created: false },
            model: object_class,
            version: an_instance_of(Float),
          ),
          routing_key: expected_routing_key, # defined by callable by default
          headers:, # defined by callable by default
        )
      end

      it "calls Rabbit#publish with attributes" do
        expect(Rabbit).to receive(:publish).with(rabbit_params)

        described_class.new(attributes).publish_now
      end
    end
  end
end

# needs let(:attributes)
shared_examples "publisher#new without expected fields" do |publisher_class, required_attributes|
  required_attributes.each do |attribute|
    context "without #{attribute}" do
      it "raises an error" do
        expect { publisher_class.new(attributes.except(attribute)) }.to raise_error do |error|
          expect(error).to be_an_instance_of(ArgumentError)
          expect(error.message).to eq(
            "Some of required attributes is not provided: [:#{attribute}]",
          )
        end
      end
    end
  end
end

# needs let(:existing_user)
shared_examples "publisher#publish_now with real user, for given orm" do |orm|
  let(:user) { DB[:users].where(id: existing_user.id).first }
  let(:expected_object_data) { [a_hash_including(user)] }

  before { TableSync.orm = orm }

  include_examples "publisher#publish_now without stubbed message"
end

# needs let(:job) with perform_at defined
# needs let(:attributes)
# needs let(expected_job_attributes)

shared_examples "publisher#publish_later behaviour" do |expected_method|
  describe "#publish_later" do
    context "with defined job" do
      before do
        TableSync.batch_publishing_job_class_callable  = -> { job }
        TableSync.single_publishing_job_class_callable = -> { job }
      end

      it "calls job with serialized original_attributes" do
        expect(job).to receive(expected_method).with(expected_job_attributes)

        described_class.new(attributes).publish_later
      end
    end

    context "without defined job" do
      before do
        TableSync.batch_publishing_job_class_callable = nil
        TableSync.single_publishing_job_class_callable = nil
      end

      it "raises no job error" do
        expect { described_class.new(attributes).publish_later }
          .to raise_error(TableSync::NoCallableError)
      end
    end
  end
end
