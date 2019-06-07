# frozen_string_literal: true

[TableSync::Model::Sequel, TableSync::Model::ActiveRecord].each do |model_class|
  describe model_class do
    let(:players) { described_class.new(:players) }
    let(:clients) { described_class.new(:clients) }
    let(:users) { described_class.new(:users) }
    let(:items) { described_class.new(:items) }

    it "#columns" do
      expect(players.columns)
        .to eq(%i[external_id project_id email online_status version rest])
      expect(clients.columns)
        .to eq(%i[client_id project_id name ext_id ext_project_id ts_version ts_rest])
    end

    it "#primary_keys" do
      expect(players.primary_keys).to eq(%i[external_id])
      expect(clients.primary_keys).to eq(%i[client_id project_id])
    end

    describe "#upsert" do
      it "raises error" do
        error = if described_class == TableSync::Model::Sequel
                  Sequel::NotNullConstraintViolation
                else
                  ActiveRecord::NotNullViolation
                end

        expect do
          clients.upsert(
            data: { name: "test", ext_id: 1, ext_project_id: 1, ts_version: 1, ts_rest: { a: 1 } },
            target_keys: %i[ext_id ext_project_id],
            version_key: :ts_version,
            default_values: {},
            first_sync_time_key: nil,
          )
        end.to raise_error(error)
      end

      it "creates" do
        result = clients.upsert(
          data: { name: "test", ext_id: 1, ext_project_id: 1, ts_version: 1, ts_rest: { a: 1 } },
          target_keys: %i[ext_id ext_project_id],
          version_key: :ts_version,
          default_values: { client_id: 1, project_id: 1 },
          first_sync_time_key: nil,
        )

        expect(result).to eq([{
          client_id: 1,
          project_id: 1,
          name: "test",
          ext_id: 1,
          ext_project_id: 1,
          ts_version: 1,
          ts_rest: { "a" => 1 },
        }])
      end

      context "with first_time_sync_key" do
        before { Timecop.freeze("2019-01-01 00:00Z") }

        specify do
          result = users.upsert(
            data: { name: "test3", ext_id: 222, ext_project_id: 333, version: 124 },
            target_keys: %i[ext_id ext_project_id],
            version_key: :version,
            default_values: { email: "mail3", id: 1 },
            first_sync_time_key: :first_sync_time,
          )

          expect(result).to eq([{
            id: 1,
            name: "test3",
            email: "mail3",
            ext_id: 222,
            ext_project_id: 333,
            version: 124,
            rest: nil,
            first_sync_time: Time.utc("2019", "01", "01", "00", "00"),
          }])
        end
      end

      context "when milti update" do
        it "creates" do # rubocop:disable RSpec/ExampleLength
          result = clients.upsert(
            data: [
              { client_id: 1, project_id: 1, name: "test", ext_id: 1, ext_project_id: 1,
                ts_version: 1, ts_rest: { a: 1 } },
              { client_id: 2, project_id: 1, name: "test2", ext_id: 2, ext_project_id: 1,
                ts_version: 1, ts_rest: { a: 2 } },
            ],
            target_keys: %i[ext_id ext_project_id],
            version_key: :ts_version,
            default_values: {},
            first_sync_time_key: nil,
          )

          expect(result).to eq([
            {
              client_id: 1,
              project_id: 1,
              name: "test",
              ext_id: 1,
              ext_project_id: 1,
              ts_version: 1,
              ts_rest: { "a" => 1 },
            },
            {
              client_id: 2,
              project_id: 1,
              name: "test2",
              ext_id: 2,
              ext_project_id: 1,
              ts_version: 1,
              ts_rest: { "a" => 2 },
            },
          ])
        end
      end

      describe "#update" do
        describe "table with composite primary keys" do
          before do
            DB[:clients].multi_insert([
              {
                client_id: 111,
                project_id: 111,
                name: "test1",
                ext_id: 222,
                ext_project_id: 222,
                ts_version: 123,
              },
              {
                client_id: 222,
                project_id: 222,
                name: "test1",
                ext_id: 111,
                ext_project_id: 111,
                ts_version: 123,
              },
            ])

            Timecop.freeze("2019-01-01 00:00Z") do
              users.upsert(
                data: { name: "test3", ext_id: 222, ext_project_id: 333, version: 124 },
                target_keys: %i[ext_id ext_project_id],
                version_key: :version,
                default_values: { email: "mail3", id: 1 },
                first_sync_time_key: :first_sync_time,
              )
            end

            Timecop.freeze("2019-02-04 01:56Z")
          end

          it "updates by pk" do
            pending if described_class == TableSync::Model::ActiveRecord

            result = clients.upsert(
              data: { name: "test2", client_id: 222, project_id: 222, ts_version: 124 },
              target_keys: %i[client_id project_id],
              version_key: :ts_version,
              default_values: { ext_id: 333, ext_project_id: 333 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([{
              client_id: 222,
              project_id: 222,
              name: "test2",
              ext_id: 111,
              ext_project_id: 111,
              ts_version: 124,
              ts_rest: nil,
            }])
          end

          it "updates by composite unique constraint" do
            pending if described_class == TableSync::Model::ActiveRecord

            result = clients.upsert(
              data: { name: "test2", ext_id: 222, ext_project_id: 222, ts_version: 124 },
              target_keys: %i[ext_id ext_project_id],
              version_key: :ts_version,
              default_values: { client_id: 333, project_id: 333 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([{
              client_id: 111,
              project_id: 111,
              name: "test2",
              ext_id: 222,
              ext_project_id: 222,
              ts_version: 124,
              ts_rest: nil,
            }])
          end

          it "does nothing if version is less" do
            result = clients.upsert(
              data: { name: "test2", ext_id: 222, ext_project_id: 222, ts_version: 123 },
              target_keys: %i[ext_id ext_project_id],
              version_key: :ts_version,
              default_values: { client_id: 333, project_id: 333 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([])
          end

          it "does not update first_sync_time_key" do
            result = users.upsert(
              data: { name: "test4", ext_id: 222, ext_project_id: 333, version: 125 },
              target_keys: %i[ext_id ext_project_id],
              version_key: :version,
              default_values: { email: "mail3", id: 1 },
              first_sync_time_key: :first_sync_time,
            )

            expect(result).to eq([{
              id: 1,
              name: "test4",
              email: "mail3",
              ext_id: 222,
              ext_project_id: 333,
              version: 125,
              rest: nil,
              first_sync_time: Time.utc("2019", "01", "01", "00", "00"),
            }])
          end

          context "when multi update" do
            it "updates by composite unique constraint" do # rubocop:disable RSpec/ExampleLength
              pending if described_class == TableSync::Model::ActiveRecord

              result = clients.upsert(
                data: [
                  { name: "test2", ext_id: 222, ext_project_id: 222, ts_version: 124,
                    client_id: 333, project_id: 333 },
                  { name: "test3", ext_id: 223, ext_project_id: 222, ts_version: 124,
                    client_id: 334, project_id: 333 },
                ],
                target_keys: %i[ext_id ext_project_id],
                version_key: :ts_version,
                default_values: {},
                first_sync_time_key: nil,
              )

              expect(result).to eq([
                {
                  client_id: 333,
                  project_id: 333,
                  name: "test2",
                  ext_id: 222,
                  ext_project_id: 222,
                  ts_version: 124,
                  ts_rest: nil,
                }, {
                  client_id: 334,
                  project_id: 333,
                  name: "test3",
                  ext_id: 223,
                  ext_project_id: 222,
                  ts_version: 124,
                  ts_rest: nil,
                }
              ])
            end
          end
        end

        describe "table without composite primary keys" do
          before do
            DB[:users].multi_insert([
              {
                id: 111,
                name: "test1",
                email: "mail1",
                ext_id: 111,
                ext_project_id: 333,
                version: 123,
                rest: nil,
              },
              {
                id: 222,
                name: "test2",
                email: "mail2",
                ext_id: 222,
                ext_project_id: 333,
                version: 12.546,
                rest: nil,
              },
            ])
          end

          it "updates by pk" do
            result = users.upsert(
              data: { name: "test3", id: 222, version: 124 },
              target_keys: %i[id],
              version_key: :version,
              default_values: { email: "mail3", ext_id: 1, ext_project_id: 1 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([{
              id: 222,
              name: "test3",
              email: "mail2",
              ext_id: 222,
              ext_project_id: 333,
              version: 124,
              rest: nil,
              first_sync_time: nil,
            }])
          end

          it "updates by composite unique constraint" do
            result = users.upsert(
              data: { name: "test3", ext_id: 222, ext_project_id: 333, version: 124 },
              target_keys: %i[ext_id ext_project_id],
              version_key: :version,
              default_values: { email: "mail3", id: 1 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([{
              id: 222,
              name: "test3",
              email: "mail2",
              ext_id: 222,
              ext_project_id: 333,
              version: 124,
              rest: nil,
              first_sync_time: nil,
            }])
          end

          it "does nothing if version is less" do
            result = users.upsert(
              data: { name: "test3", ext_id: 222, ext_project_id: 333, version: 1 },
              target_keys: %i[ext_id ext_project_id],
              version_key: :version,
              default_values: { email: "mail3", id: 1 },
              first_sync_time_key: nil,
            )

            expect(result).to eq([])
          end

          context "when multi update" do
            it "updates by pk" do # rubocop:disable RSpec/ExampleLength
              result = users.upsert(
                data: [
                  { id: 1, name: "test2", ext_id: 222, ext_project_id: 222, version: 124 },
                  { id: 2, name: "test3", ext_id: 223, ext_project_id: 222, version: 124 },
                ],
                target_keys: %i[ext_id ext_project_id],
                version_key: :version,
                default_values: { email: "mail3" },
                first_sync_time_key: nil,
              )

              expect(result).to eq([
                {
                  id: 1,
                  name: "test2",
                  email: "mail3",
                  ext_id: 222,
                  ext_project_id: 222,
                  version: 124,
                  rest: nil,
                  first_sync_time: nil,
                }, {
                  id: 2,
                  name: "test3",
                  email: "mail3",
                  ext_id: 223,
                  ext_project_id: 222,
                  version: 124,
                  rest: nil,
                  first_sync_time: nil,
                }
              ])
            end
          end
        end
      end
    end

    describe "#destroy" do
      it "destroys in table with composite primary keys" do # rubocop:disable RSpec/ExampleLength
        pending if described_class == TableSync::Model::ActiveRecord

        DB[:clients].multi_insert([
          {
            client_id: 111,
            project_id: 111,
            name: "test1",
            ext_id: 222,
            ext_project_id: 222,
            ts_version: 123,
          },
          {
            client_id: 222,
            project_id: 222,
            name: "test2",
            ext_id: 111,
            ext_project_id: 111,
            ts_version: 123,
          },
        ])

        result = clients.destroy(client_id: 111, project_id: 111)
        expect(result).to eq([{
          client_id: 111,
          project_id: 111,
          name: "test1",
          ext_id: 222,
          ext_project_id: 222,
          ts_version: 123,
          ts_rest: nil,
        }])
      end

      it "destroys im table without composite primary keys" do # rubocop:disable RSpec/ExampleLength
        DB[:players].multi_insert([
          {
            external_id: 111,
            project_id: "pid1",
            email: "435",
            online_status: true,
            version: 12.343,
            rest: nil,
          },
          {
            external_id: 222,
            project_id: "pid2",
            email: "fghgf",
            online_status: false,
            version: 122.565,
            rest: nil,
          },
        ])

        result = players.destroy(external_id: 222, project_id: "pid2")
        expect(result).to eq([{
          external_id: 222,
          project_id: "pid2",
          email: "fghgf",
          online_status: false,
          version: 122.565,
          rest: nil,
        }])
      end
    end

    describe "transaction and after_commit" do
      let(:checks) { [] }

      before { DB[:items].insert(id: 1, name: "test", price: 123) }

      it "fails transaction" do
        begin
          items.transaction do
            expect(items.destroy(id: 1)).to eq([{ id: 1, name: "test", price: 123 }])
            items.after_commit { checks[0] = "test_after_commit" }
            raise "test error"
          end
        rescue => e
          raise e if e.message != "test error"
        end

        expect(checks).to eq([])
        expect(DB[:items].count).to eq(1)
      end

      it "calls callbacks" do
        items.transaction do
          expect(items.destroy(id: 1)).to eq([{ id: 1, name: "test", price: 123 }])
          items.after_commit { checks[0] = "test_after_commit" }
        end
        expect(checks).to eq(["test_after_commit"])
        expect(DB[:items].count).to eq(0)
      end
    end
  end
end
