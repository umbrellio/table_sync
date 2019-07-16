# frozen_string_literal: true

describe TableSync::ReceivingHandler do
  before { allow(TableSync).to receive(:orm).and_return(TableSync::ORMAdapter::Sequel) }

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
      expect(handler.data).to eq(
        id: 33,
        name: "test1",
        nickname: "test2",
        balance: 1221,
        email: "mail@example.com",
      )
      expect(handler.version).to eq(123.34534)
      expect(handler.project_id).to eq("pid")
    end
  end

  describe "with no configs" do
    let(:handler) { described_class }

    specify { expect { fire_update_event }.to raise_error TableSync::UndefinedConfig }
  end

  describe "with config" do
    let(:callback_flags) do
      { update1: 0, update2: 0, update3: 0, destroy: 0, before_commit_update: 0 }
    end

    let(:handler) do
      cf = callback_flags

      handler = Class.new(TableSync::ReceivingHandler)

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

        before_commit on: :update do
          cf[:before_commit_update] += 1
        end

        after_commit on: :update do
          cf[:update1] += 1
        end

        after_commit on: :update do
          cf[:update2] += 1
        end

        after_commit on: :destroy do
          cf[:destroy] += 1
        end

        default_values(client_id: 22, project_id: 22, name: "native_name")
      end

      handler.receive("User", to_table: :players) do
        rest_key false
        mapping_overrides id: :external_id
        only :external_id, :project_id, :email
        additional_data { |project_id:| { project_id: project_id.upcase } }

        after_commit on: :update do
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
          handler = Class.new(TableSync::ReceivingHandler)

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
          Class.new(TableSync::ReceivingHandler).tap do |handler|
            handler.receive("User", to_table: :players) do
              mapping_overrides id: :external_id
              additional_data { |project_id:| { project_id: project_id.upcase } }

              before_commit on: :update do |attrs, _|
                DB[:clients].insert(client_id: attrs[:external_id],
                                    project_id: 777,
                                    name: attrs[:rest][:name],
                                    ext_id: 666,
                                    ext_project_id: 9)

                attrs[:rest][:nickname] = "hi_i_got_hacked"
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
          handler = Class.new(TableSync::ReceivingHandler)

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

      context "multi update with partitions and changed data" do
        let(:skip_block) { nil }
        let(:handler) do
          handler = Class.new(TableSync::ReceivingHandler)
          skip_proc = skip_block.presence

          handler.receive("User", to_table: :players) do
            rest_key false
            mapping_overrides id: :external_id
            only :external_id, :project_id, :email

            partitions do |data:|
              DB.run('CREATE TABLE IF NOT EXISTS "players_part_3"'\
                     '(like "players_part_1" INCLUDING ALL);')

              parts = { "test2" => "players_part_1", "test5" => "players_part_3" }

              data.group_by { |d| d[:nickname] }.transform_keys { |k| Sequel.lit(parts[k]) }
            end

            skip &skip_proc

            additional_data do |project_id:, current_row:|
              { project_id: project_id.upcase, email: current_row[:email].downcase }
            end
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
                  email: "MAIL@example.com",
                },
                {
                  id: 34,
                  name: "test4",
                  nickname: "test5",
                  balance: 1225,
                  email: "MAIL2@example.com",
                },
                {
                  id: 35,
                  name: "test5",
                  nickname: "test2",
                  balance: 1225,
                  email: "MAIL3@example.com",
                },
              ],
              version: 123.34534,
            },
            project_id: "pid",
          )
        end

        specify do
          expect(DB[:players_part_1].count).to eq(2)
          expect(DB[:players_part_1].first).to match(
            email: "mail@example.com",
            external_id: 33,
            online_status: nil,
            project_id: "PID",
            rest: nil,
            version: 123.34534,
          )

          expect(DB[:players_part_1].all.second).to match(
            email: "mail3@example.com",
            external_id: 35,
            online_status: nil,
            project_id: "PID",
            rest: nil,
            version: 123.34534,
          )

          expect(DB[:players_part_3].count).to eq(1)
          expect(DB[:players_part_3].first).to match(
            email: "mail2@example.com",
            external_id: 34,
            online_status: nil,
            project_id: "PID",
            rest: nil,
            version: 123.34534,
          )
        end

        context "when skip config is defined" do
          let(:skip_block) do
            proc do |current_row:|
              current_row[:id] > 33
            end
          end

          it "skips rows for which 'skip' callback returns true" do
            expect(DB[:players_part_1].count).to eq(1)
            expect(DB[:players_part_1].first).to match(
              email: "mail@example.com",
              external_id: 33,
              online_status: nil,
              project_id: "PID",
              rest: nil,
              version: 123.34534,
            )
            expect(DB[:players_part_3].count).to eq(0)
          end
        end
      end

      context "when on_destroy is defined" do
        before { stub_const("DESTROY_INTERCEPTOR", []) }

        let(:handler) do
          Class.new(TableSync::ReceivingHandler).tap do |handler|
            handler.receive("User", to_table: :players) do
              mapping_overrides id: :external_id
              additional_data { |project_id:| { project_id: project_id.upcase } }
              on_destroy do |attributes:, target_keys:|
                DESTROY_INTERCEPTOR.push(attributes: attributes, target_keys: target_keys)
                "on_destroy_completed" # returning value
              end

              after_commit on: :destroy do |results|
                DESTROY_INTERCEPTOR.push(results) # results == 'on_destroy_completed'
              end
            end
          end
        end

        let(:expected_on_destroy_attrs) do
          {
            target_keys: [:external_id],
            attributes: {
              external_id: 33,
              rest: {},
              version: nil,
              project_id: "PID",
            },
          }
        end

        let(:expected_on_destroy_results) do
          "on_destroy_completed"
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
          handler = Class.new(TableSync::ReceivingHandler)

          handler.receive("User", to_table: :players) do
            rest_key false
            mapping_overrides id: :external_id

            additional_data { |project_id:| { project_id: project_id.upcase } }

            skip do |event:, data:|
              if event == :destroy
                data[:id] > 32
              else
                data[:balance] && data[:balance] > 1000
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
end
