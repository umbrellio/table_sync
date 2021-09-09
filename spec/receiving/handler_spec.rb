# frozen_string_literal: true

describe TableSync::Receiving::Handler do
  before do
    allow(TableSync).to receive(:receiving_model).and_return(TableSync::Receiving::Model::Sequel)
  end

  let(:update_event) do
    OpenStruct.new(
      data: {
        event: "update",
        model: "User",
        attributes: {
          id: user_id,
          name: "test1",
          nickname: "test2",
          balance: user_balance,
          email: "mail@example.com",
        },
        version: 123.34534,
      },
      project_id: "pid",
    )
  end
  let(:user_id)      { 33 }
  let(:user_balance) { 1221 }

  let(:destroy_event) do
    OpenStruct.new(
      data: {
        event: "destroy",
        model: "User",
        attributes: { id: user_id },
      },
      project_id: "pid",
    )
  end

  def fire_update_event
    handler.new(update_event).call
  end

  def fire_destroy_event
    handler.new(destroy_event).call
  end

  describe "initialization" do
    let(:handler) { described_class.new(update_event) }

    it "sets attributes right" do
      expect(handler.event).to eq(:update)
      expect(handler.model).to eq("User")
      expect(handler.data).to eq([
        { id: 33,
          name: "test1",
          nickname: "test2",
          balance: 1221,
          email: "mail@example.com" },
      ])
      expect(handler.version).to eq(123.34534)
      expect(handler.project_id).to eq("pid")
    end
  end

  describe "#wrap_receiving" do
    let(:handler) do
      cool_wrapper = wrapper

      handler = Class.new(described_class)

      handler.receive("User", to_table: :players) do
        rest_key false
        mapping_overrides id: :external_id
        only :external_id, :project_id, :email

        wrap_receiving do |event:, **_rest, &receiving|
          cool_wrapper.call(event: event)
          receiving.call
        end
      end

      handler
    end
    let(:wrapper) { double("CoolWrapper", call: {}) }

    it "provides proper event to wrap receiving" do
      fire_update_event
      expect(wrapper).to have_received(:call).with(event: :update)

      fire_destroy_event
      expect(wrapper).to have_received(:call).with(event: :destroy)
    end
  end

  describe "with config" do
    let(:callback_flags) do
      { update1: 0, update2: 0, update3: 0, destroy: 0, before_commit_update: 0 }
    end

    let(:handler) do
      cf = callback_flags

      handler = Class.new(described_class)

      handler.receive("User", to_table: :clients) do
        mapping_overrides(id: :ext_id)
        only(:ext_id, :ext_project_id)
        rest_key(:ts_rest)
        version_key(:ts_version)
        target_keys(:ext_id, :ext_project_id)

        additional_data do |project_id:|
          raise "undefined project" if project_id != "pid"
          { ext_project_id: 333 }
        end

        before_update do
          cf[:before_commit_update] += 1
        end

        after_commit_on_update do
          cf[:update1] += 1
        end

        after_commit_on_update do
          cf[:update2] += 1
        end

        after_commit_on_destroy do
          cf[:destroy] += 1
        end

        default_values(client_id: 22, project_id: 22, name: "native_name")
      end

      handler.receive("User", to_table: :players) do
        rest_key false
        mapping_overrides id: :external_id
        only :external_id, :project_id, :email
        additional_data { |project_id:| { project_id: project_id.upcase } }

        after_commit_on_update do
          cf[:update3] += 1
        end
      end

      handler
    end

    let(:expected_client_attrs) do
      {
        client_id: 22,
        project_id: 22,
        name: "native_name",
        ext_id: 33,
        ext_project_id: 333,
        ts_version: 123.34534,
        ts_rest: {
          "name" => "test1",
          "balance" => 1221,
          "nickname" => "test2",
          "email" => "mail@example.com",
        },
      }
    end

    let(:expected_player_attrs) do
      {
        email: "mail@example.com",
        external_id: 33,
        online_status: nil,
        project_id: "PID",
        rest: nil,
        version: 123.34534,
      }
    end

    it "checks callbacks with transaction" do
      DB.transaction do
        fire_update_event
        expect(DB[:clients].count).to eq(1)
        expect(callback_flags)
          .to eq(update1: 0, update2: 0, update3: 0, destroy: 0, before_commit_update: 1)

        fire_destroy_event
        expect(DB[:clients].count).to eq(0)
        expect(callback_flags)
          .to eq(update1: 0, update2: 0, update3: 0, destroy: 0, before_commit_update: 1)
      end

      expect(callback_flags)
        .to eq(update1: 1, update2: 1, update3: 1, destroy: 1, before_commit_update: 1)
    end

    context "when update event fires" do
      before { fire_update_event }

      it "process events" do
        expect(DB[:clients].count).to eq(1)
        expect(DB[:clients].first).to match(expected_client_attrs)

        expect(DB[:players].count).to eq(1)
        expect(DB[:players].first).to match(expected_player_attrs)

        expect(callback_flags)
          .to eq(update1: 1, update2: 1, update3: 1, destroy: 0, before_commit_update: 1)

        # Insert a random client to make sure destroy does not delete everything
        DB[:clients].insert(client_id: 34,
                            project_id: 22,
                            name: "test",
                            ext_id: 35,
                            ext_project_id: 36)

        fire_destroy_event
        expect(DB[:clients].count).to eq(1)
        expect(DB[:players].count).to eq(0)

        expect(callback_flags)
          .to eq(update1: 1, update2: 1, update3: 1, destroy: 1, before_commit_update: 1)
      end

      context "incoming rest" do
        let(:handler) do
          handler = Class.new(described_class)

          handler.receive("User", to_table: :players) do
            mapping_overrides id: :external_id
            additional_data { |project_id:| { project_id: project_id.upcase } }
          end

          handler
        end

        let(:update_event) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "User",
              attributes: {
                id: 33,
                name: "test1",
                nickname: "test2",
                balance: 1221,
                email: "mail@example.com",
                rest: { first: "1" },
              },
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it "is being merged into existing rest" do
          expect(DB[:players].first[:rest].keys).to match_array(%w[name first balance nickname])
        end
      end

      context "performing actions in before_commit" do
        let(:handler) do
          Class.new(described_class).tap do |handler|
            handler.receive("User", to_table: :players) do
              mapping_overrides id: :external_id
              additional_data { |project_id:| { project_id: project_id.upcase } }

              before_update do |data:|
                data.each do |row|
                  DB[:clients].insert(client_id: row[:external_id],
                                      project_id: 777,
                                      name: row[:rest][:name],
                                      ext_id: 666,
                                      ext_project_id: 9)

                  row[:rest][:nickname] = "hi_i_got_hacked"
                end
              end
            end
          end
        end

        let(:update_event) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "User",
              attributes: {
                id: 33,
                name: "test1",
                nickname: "test2",
                balance: 1221,
                email: "mail@example.com",
                rest: { first: "1" },
              },
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        it "creates a client" do
          expect(DB[:clients].count).to eq(1)
          expect(DB[:clients].first).to include(
            client_id: 33,
            project_id: 777,
            name: "test1",
            ext_id: 666,
            ext_project_id: 9,
          )
        end

        it "changes user's nickname" do
          expect(DB[:players].first[:rest]["nickname"]).to eq("hi_i_got_hacked")
        end
      end

      context "multi update" do
        let(:handler) do
          handler = Class.new(described_class)

          handler.receive("User", to_table: :players) do
            rest_key false
            mapping_overrides id: :external_id
            only :external_id, :project_id, :email
            additional_data { |project_id:| { project_id: project_id.upcase } }
          end

          handler
        end

        let(:update_event) do
          OpenStruct.new(
            data: {
              event: "update",
              model: "User",
              attributes: [
                {
                  id: 33,
                  name: "test1",
                  nickname: "test2",
                  balance: 1221,
                  email: "mail@example.com",
                },
                {
                  id: 34,
                  name: "test4",
                  nickname: "test5",
                  balance: 1225,
                  email: "mail2@example.com",
                },
              ],
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        specify do
          expect(DB[:players].count).to eq(2)
          expect(DB[:players].first).to match(
            email: "mail@example.com",
            external_id: 33,
            online_status: nil,
            project_id: "PID",
            rest: nil,
            version: 123.34534,
          )

          expect(DB[:players].all.second).to match(
            email: "mail2@example.com",
            external_id: 34,
            online_status: nil,
            project_id: "PID",
            rest: nil,
            version: 123.34534,
          )
        end
      end

      context "with custom model" do
        before { stub_const("DESTROY_INTERCEPTOR", []) }

        let(:model) do
          Class.new(TableSync.receiving_model) do
            def destroy(data:, target_keys:, version_key:)
              DESTROY_INTERCEPTOR.push(data: data, target_keys: target_keys)
              [{ text: "on_destroy_completed" }] # returning value
            end
          end.new(:players)
        end

        let(:handler) do
          Class.new(described_class).tap do |handler|
            handler.receive("User", to_model: model) do
              mapping_overrides id: :external_id
              additional_data { |project_id:| { project_id: project_id.upcase } }

              after_commit_on_destroy do |results:|
                DESTROY_INTERCEPTOR.push(results) # results == [{text: "on_destroy_completed"}]
              end
            end
          end
        end

        let(:expected_on_destroy_attrs) do
          {
            target_keys: [:external_id],
            data: [{
              external_id: 33,
              rest: {},
              version: nil,
              project_id: "PID",
            }],
          }
        end

        let(:expected_on_destroy_results) do
          [{ text: "on_destroy_completed" }]
        end

        specify "uses custom destroying logic instead of the real destroying" do
          expect(DB[:players].count).to eq(1)
          expect(DESTROY_INTERCEPTOR).to be_empty

          fire_destroy_event
          expect(DB[:players].count).to eq(1)
          expect(DESTROY_INTERCEPTOR).to contain_exactly(
            expected_on_destroy_attrs,
            expected_on_destroy_results,
          )

          fire_destroy_event
          expect(DB[:players].count).to eq(1)
          expect(DESTROY_INTERCEPTOR).to contain_exactly(
            expected_on_destroy_attrs,
            expected_on_destroy_results,
            expected_on_destroy_attrs,
            expected_on_destroy_results,
          )
        end
      end

      context "when skip config is defined" do
        let(:handler) do
          handler = Class.new(described_class)

          handler.receive("User", to_table: :players) do
            rest_key false
            mapping_overrides id: :external_id

            additional_data { |project_id:| { project_id: project_id.upcase } }

            skip do |event:, row:|
              if event == :destroy
                row[:id] > 32
              else
                row[:balance] && row[:balance] > 1000
              end
            end
          end

          handler
        end

        context "when 'skip' returns true" do
          it "skips row" do
            expect(DB[:players].count).to eq(0)
          end

          context "on deleting event" do
            let(:user_balance) { 900 }

            before { fire_destroy_event }

            it "skips row" do
              expect(DB[:players].count).to eq(1)
            end
          end
        end

        context "when 'skip' returns false" do
          let(:user_id)      { 32 }
          let(:user_balance) { 900 }

          it "processes row" do
            expect(DB[:players].count).to eq(1)
          end

          context "on deleting event" do
            it "processes row" do
              expect(DB[:players].count).to eq(1)

              fire_destroy_event
              expect(DB[:players].count).to eq(0)
            end
          end
        end
      end
    end
  end

  describe "data validations" do
    let(:update_event) do
      OpenStruct.new(
        data: {
          event: "update",
          model: "User",
          attributes: [
            {
              id: user_id,
              name: "test1",
              nickname: "test2",
              balance: user_balance,
              email: "mail@example.com",
            },
            {
              id: user_id,
              name: "test1",
              nickname: "test2",
              balance: user_balance,
              email: "mail@example.com",
            },
          ],
          version: 123.34534,
        },
        project_id: "pid",
      )
    end

    describe "error with target keys" do
      let(:handler) do
        Class.new(described_class).receive("User", to_table: :users) do
          except :id
          target_keys(:id)
        end
      end

      it "raises TableSync::DataError" do
        expect { fire_update_event }.to raise_error(TableSync::DataError)
      end
    end

    describe "error with duplicate rows" do
      let(:handler) do
        Class.new(described_class).receive("User", to_table: :users) do
          target_keys(:id)
        end
      end

      it "raises TableSync::DataError" do
        expect { fire_update_event }.to raise_error(TableSync::DataError)
      end
    end

    describe "error with data structure" do
      let(:handler) do
        Class.new(described_class).receive("User", to_table: :users) do
          target_keys(:id)
        end
      end

      let(:update_event) do
        OpenStruct.new(
          data: {
            event: "update",
            model: "User",
            attributes: [
              {
                id: 1,
                name: "test1",
              },
              {
                id: 2,
                name: "test2",
                nickname: "test2",
                balance: 123131,
                email: "mail@example.com",
              },
            ],
            version: 123.34534,
          },
          project_id: "pid",
        )
      end

      it "raises TableSync::DataError" do
        expect { fire_update_event }.to raise_error(TableSync::DataError)
      end
    end
  end

  describe "avoid dead locks" do
    let(:model) do
      Class.new(TableSync.receiving_model) do
        def upsert(data:, target_keys:, version_key:, default_values:)
          data.each do |row|
            conditions = row.select { |key| target_keys.include?(key) }
            dataset.where(conditions).update(row)
            sleep 2
          end
        end
      end
    end

    context "by rows" do
      let(:handler) do
        Class.new(described_class).receive("Stat1", to_model: model.new(:stat1)) do
          rest_key false
        end
      end

      let(:update_event1) do
        OpenStruct.new(
          data: {
            event: "update",
            model: "Stat1",
            attributes: [{ id: 1, value: 1 }, { id: 2, value: 1 }],
            version: 2,
          },
          project_id: "pid",
        )
      end

      let(:update_event2) do
        OpenStruct.new(
          data: {
            event: "update",
            model: "Stat1",
            attributes: [{ id: 2, value: 1 }, { id: 1, value: 1 }],
            version: 2,
          },
          project_id: "pid",
        )
      end

      specify do
        DB[:stat1].multi_insert([
          { id: 1, value: 1, version: 1 },
          { id: 2, value: 1, version: 1 },
        ])

        threads = []
        threads << Thread.new(handler, update_event1) do |handler, event|
          DB.transaction { handler.new(event).call }
        end
        threads << Thread.new(handler, update_event2) do |handler, event|
          DB.transaction { handler.new(event).call }
        end
        threads.each(&:join)
      end
    end

    context "by configs" do
      let(:handler1) do
        Class.new(described_class)
          .receive("Stat", to_model: model.new(:stat1)) { rest_key false }
          .receive("Stat", to_model: model.new(:stat2)) { rest_key false }
      end

      let(:handler2) do
        Class.new(described_class)
          .receive("Stat", to_model: model.new(:stat2)) { rest_key false }
          .receive("Stat", to_model: model.new(:stat1)) { rest_key false }
      end

      let(:update_event) do
        OpenStruct.new(
          data: {
            event: "update",
            model: "Stat",
            attributes: [{ id: 1, value: 1 }],
            version: 2,
          },
          project_id: "pid",
        )
      end

      specify do
        DB[:stat1].insert({ id: 1, value: 1, version: 1 })
        DB[:stat2].insert({ id: 1, value: 1, version: 1 })

        threads = []
        threads << Thread.new(handler1, update_event) do |handler, event|
          DB.transaction { handler.new(event).call }
        end
        threads << Thread.new(handler2, update_event) do |handler, event|
          DB.transaction { handler.new(event).call }
        end
        threads.each(&:join)
      end
    end
  end
end
