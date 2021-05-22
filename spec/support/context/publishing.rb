# frozen_string_literal: true

# needs let(:attributes) { #attrs }
shared_examples "publisher#publish_now calls stubbed message with attributes" do |message_class|
	describe "#publish_now" do
		context "with stubbed message" do
  		let(:event)          { :update }
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

# needs let(:job) with perform_later defined
# needs let(:attributes)
# needs let(:original_attributes) with unserializable value
# needs let(:serialized_attributes) -> original_attributes without unserializable value

shared_examples "publisher#publish_later behaviour" do
	describe "#publish_later" do
		context "with defined job" do
			before do
				TableSync.batch_publishing_job_class_callable = -> { job }
				TableSync.single_publishing_job_class_callable = -> { job }
			end

			it "calls BatchJob with serialized original_attributes" do
				expect(job).to receive(:perform_later).with(
					attributes.merge(original_attributes: serialized_attributes)
				)

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
					.to raise_error(TableSync::NoJobClassError)
			end
		end
	end
end
