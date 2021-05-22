# frozen_string_literal: true

TableSync.orm = :sequel

# check for active record?

class User < Sequel::Model; end

RSpec.describe TableSync::Publishing::Single do
  let(:original_attributes)   { { id: 1, time: Time.current } }
  let(:serialized_attributes) { { id: 1 } }
  let(:event)									{ :update }

  let(:attributes) do
  	{
			object_class: "User",
  		original_attributes: original_attributes,
  		event: event,
  		debounce_time: 30,
  	}
  end

	include_examples "publisher#publish_now calls stubbed message with attributes",
		TableSync::Publishing::Message::Single

	context "#publish_later" do
		context "empty message" do
			let(:original_attributes) { { id: 1 } }

			before do
				TableSync.routing_key_callable = -> (klass, attributes) { klass }
				TableSync.headers_callable     = -> (klass, attributes) { klass }
			end

			context "create" do
				let(:event) { :create }

				it "doesn't publish" do
					expect(Rabbit).not_to receive(:publish)
					described_class.new(attributes).publish_now
				end
			end

			context "update" do
				let(:event) { :update }

				it "doesn't publish" do
					expect(Rabbit).not_to receive(:publish)
					described_class.new(attributes).publish_now
				end
			end

			context "destroy" do
				let(:event) { :destroy }

				it "publishes" do
					expect(Rabbit).to receive(:publish)
					described_class.new(attributes).publish_now
				end
			end
		end
	end

	context "#publish_later" do
		let(:job) { double("Job", perform_later: 1) }

		include_examples "publisher#publish_later behaviour"

		context "with debounce" do
			it "skips job, returns nil" do
			end
		end
	end
end


# class User < Sequel::Model
# end

# TableSync.orm = :sequel

# TableSync.routing_key_callable = -> (klass, attributes) { "#{klass}_#{attributes[:ext_id]}" }
# TableSync.headers_callable     = -> (klass, attributes) { "#{klass}_#{attributes[:ext_id]}" }
# TableSync.exchange_name        = :test

		# context "event" do
		# 	let(:routing_key) { "#{object_class}_#{ext_id}" }
  # 		let(:headers)		  { "#{object_class}_#{ext_id}" }

		# 	let(:published_message) do
		# 		{
		# 			confirm_select: true,
  #  				event: :table_sync,
  #  				exchange_name: :test,
  #  				headers: headers,
  #  				realtime: true,
  #  				routing_key: routing_key,
  #  				data: {
  #   				attributes: published_attributes,
  #    				event: event,
  #    				metadata: metadata,
  #    				model: "User",
  #    				version: anything,
  #    			},
  #    		}
		# 	end

		# 	shared_examples "publishes rabbit message" do
		# 		specify do
		# 			expect(Rabbit).to receive(:publish).with(published_message)

		# 			described_class.new(attributes).publish_now
		# 		end
		# 	end

		# 	shared_examples "raises No Objects Error" do
		# 		specify do
		# 			expect { described_class.new(attributes).publish_now }
		# 				.to raise_error(TableSync::Publishing::Message::Base::NO_OBJECTS_FOR_SYNC)
		# 		end
		# 	end

		# 	shared_examples "has expected behaviour" do
		# 		context "when published object exists" do
		# 			before { User.insert(user_attributes) }

		# 			include_examples "publishes rabbit message"
		# 		end

		# 		context "when published object DOESN'T exist" do
		# 			include_examples "raises No Objects Error"
		# 		end
		# 	end

		# 	context "create" do
		# 		let(:event)                { :create }
		# 		let(:metadata)             { { created: true } }
		# 		let(:published_attributes) { [a_hash_including(user_attributes)] }

		# 		include_examples "has expected behaviour"
		# 	end

		# 	context "update" do
		# 		let(:event)    { :update }
		# 		let(:metadata) { { created: false} }
		# 		let(:published_attributes) { [a_hash_including(user_attributes)] }

		# 		include_examples "has expected behaviour"
		# 	end

		# 	context "destroy" do
		# 		let(:event)    						 { :destroy }
		# 		let(:metadata) 						 { { created: false} }
		# 		let(:published_attributes) { [user_attributes.slice(:id)] }

		# 		include_examples "publishes rabbit message"
		# 	end
		# end