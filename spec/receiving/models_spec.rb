# frozen_string_literal: true

[
  TableSync::Receiving::Model::Sequel,
  TableSync::Receiving::Model::ActiveRecord,
].each do |model_class|
  describe model_class do
    let(:players) { described_class.new(:players) }
    let(:clients) { described_class.new(:clients) }
    let(:users) { described_class.new(:users) }
    let(:types_test) { described_class.new(:types_test) }

    it "#columns" do
      expect(players.columns)
        .to eq(%i[external_id project_id email online_status version rest hooks])
      expect(clients.columns)
        .to eq(%i[client_id project_id name ext_id ext_project_id ts_version ts_rest])
    end

    it "#primary_keys" do
      expect(players.primary_keys).to eq(%i[external_id])
      expect(clients.primary_keys).to eq(%i[client_id project_id])
    end

    describe "#upsert" do
      it "raises error" do
        error = if described_class == TableSync::Receiving::Model::Sequel
                  Sequel::NotNullConstraintViolation
                else
                  ActiveRecord::NotNullViolation
                end

        expect do
          clients.upsert(
            data: [{
              name: "test",
              ext_id: 1,
              ext_project_id: 1,
              ts_version: 1,
              ts_rest: { a: 1 },
            }],
            target_keys: %i[ext_id ext_project_id],
            version_key: :ts_version,
            default_values: {},
          )
        end.to raise_error(error)
      end

      it "merges the default_values correctly" do
        result = clients.upsert(
          data: [{ name: "test", ext_id: 1, ext_project_id: 1, ts_version: 1, ts_rest: { a: 1 } }],
          target_keys: %i[ext_id ext_project_id],
          version_key: :ts_version,
          default_values: {
            client_id: 1,
            project_id: 1,
            ts_version: 2,
            name: "test123",
            ts_rest: { b: 2 },
          },
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

      it "creates" do
        result = clients.upsert(
          data: [{ name: "test", ext_id: 1, ext_project_id: 1, ts_version: 1, ts_rest: { a: 1 } }],
          target_keys: %i[ext_id ext_project_id],
          version_key: :ts_version,
          default_values: { client_id: 1, project_id: 1 },
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
            data: [{ name: "test3", ext_id: 222, ext_project_id: 333, version: 124 }],
            target_keys: %i[ext_id ext_project_id],
            version_key: :version,
            default_values: { email: "mail3", id: 1, first_sync_time: Time.current },
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
        it "creates" do
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
                data: [{ name: "test3", ext_id: 222, ext_project_id: 333, version: 124 }],
                target_keys: %i[ext_id ext_project_id],
                version_key: :version,
                default_values: { email: "mail3", id: 1, first_sync_time: Time.current },
              )
            end

            Timecop.freeze("2019-02-04 01:56Z")
          end

          it "updates by pk" do
            result = clients.upsert(
              data: [{ name: "test2", client_id: 222, project_id: 222, ts_version: 124 }],
              target_keys: %i[client_id project_id],
              version_key: :ts_version,
              default_values: { ext_id: 333, ext_project_id: 333 },
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
            result = clients.upsert(
              data: [{ name: "test2", ext_id: 222, ext_project_id: 222, ts_version: 124 }],
              target_keys: %i[ext_id ext_project_id],
              version_key: :ts_version,
              default_values: { client_id: 333, project_id: 333 },
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
              data: [{ name: "test2", ext_id: 222, ext_project_id: 222, ts_version: 123 }],
              target_keys: %i[ext_id ext_project_id],
              version_key: :ts_version,
              default_values: { client_id: 333, project_id: 333 },
            )

            expect(result).to eq([])
          end

          context "when multi update" do
            it "updates by composite unique constraint" do
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
              data: [{ name: "test3", id: 222, version: 124 }],
              target_keys: %i[id],
              version_key: :version,
              default_values: { email: "mail3", ext_id: 1, ext_project_id: 1 },
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
              data: [{ name: "test3", ext_id: 222, ext_project_id: 333, version: 124 }],
              target_keys: %i[ext_id ext_project_id],
              version_key: :version,
              default_values: { email: "mail3", id: 1 },
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
              data: [{ name: "test3", ext_id: 222, ext_project_id: 333, version: 1 }],
              target_keys: %i[ext_id ext_project_id],
              version_key: :version,
              default_values: { email: "mail3", id: 1 },
            )

            expect(result).to eq([])
          end

          context "when multi update" do
            it "updates by pk" do
              result = users.upsert(
                data: [
                  { id: 1, name: "test2", ext_id: 222, ext_project_id: 222, version: 124 },
                  { id: 2, name: "test3", ext_id: 223, ext_project_id: 222, version: 124 },
                ],
                target_keys: %i[ext_id ext_project_id],
                version_key: :version,
                default_values: { email: "mail3" },
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

        describe "result checks" do
          before do
            DB[:players].multi_insert([
              {
                external_id: 1,
                project_id: "pid1",
                email: "435",
                online_status: false,
                version: 12.343,
                rest: nil,
              },
              {
                external_id: 2,
                project_id: "pid1",
                email: "fghgf",
                online_status: false,
                version: 12.565,
                rest: nil,
              },
            ])
          end

          it "rises error" do
            error = if described_class == TableSync::Receiving::Model::Sequel
                      Sequel::DatabaseError
                    else
                      TableSync::UpsertError
                    end

            expectation = expect do
              players.upsert(
                data: [{ project_id: "pid1", online_status: true, version: 22 }],
                target_keys: %i[project_id],
                version_key: :version,
                default_values: {},
              )
            end

            expectation.to raise_error(error)
          end
        end
      end
    end

    describe "#destroy" do
      it "destroys in table with composite primary keys" do
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

        result = clients.destroy(
          data: [{ client_id: 111, project_id: 111, name: "test", ts_version: 222 }],
          target_keys: %i[client_id project_id],
          version_key: :ts_version,
        )
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

      it "destroys in table without composite primary keys" do
        DB[:players].multi_insert([
          {
            external_id: 111,
            project_id: "pid1",
            email: "435",
            online_status: true,
            version: 12.343,
            rest: nil,
            hooks: nil,
          },
          {
            external_id: 222,
            project_id: "pid2",
            email: "fghgf",
            online_status: false,
            version: 122.565,
            rest: nil,
            hooks: nil,
          },
        ])

        result = players.destroy(
          data: [{ external_id: 222, project_id: "pid2", email: "435", version: 222 }],
          target_keys: %i[external_id project_id],
          version_key: :version,
        )
        expect(result).to eq([{
          external_id: 222,
          project_id: "pid2",
          email: "fghgf",
          online_status: false,
          version: 122.565,
          rest: nil,
          hooks: nil,
        }])
      end

      it "multi destroys in table without composite primary keys" do
        DB[:players].multi_insert([
          {
            external_id: 111,
            project_id: "pid1",
            email: "435",
            online_status: true,
            version: 12.343,
            rest: nil,
            hooks: nil,
          },
          {
            external_id: 222,
            project_id: "pid2",
            email: "fghgf",
            online_status: false,
            version: 122.565,
            rest: nil,
            hooks: nil,
          },
          {
            external_id: 333,
            project_id: "pid3",
            email: "fghgfsdd",
            online_status: false,
            version: 122.5653,
            rest: nil,
            hooks: nil,
          },
        ])

        result = players.destroy(
          data: [
            { external_id: 222, project_id: "pid2", email: "435", version: 222 },
            { external_id: 111, project_id: "pid1", email: "asdsad", version: 222 },
          ],
          target_keys: %i[external_id project_id],
          version_key: :version,
        )
        expect(result).to eq([
          {
            external_id: 111,
            project_id: "pid1",
            email: "435",
            online_status: true,
            version: 12.343,
            rest: nil,
            hooks: nil,
          },
          {
            external_id: 222,
            project_id: "pid2",
            email: "fghgf",
            online_status: false,
            version: 122.565,
            rest: nil,
            hooks: nil,
          },
        ])
      end

      describe "result checks" do
        before do
          DB[:players].multi_insert([
            {
              external_id: 1,
              project_id: "pid1",
              email: "435",
              online_status: false,
              version: 12.343,
              rest: nil,
              hooks: nil,
            },
            {
              external_id: 2,
              project_id: "pid1",
              email: "fghgf",
              online_status: false,
              version: 12.565,
              rest: nil,
              hooks: nil,
            },
          ])
        end

        it "rises error" do
          expectation = expect do
            players.destroy(
              data: [{ project_id: "pid1", version: 22 }],
              target_keys: %i[project_id],
              version_key: :version,
            )
          end

          expectation.to raise_error(TableSync::DestroyError)
        end
      end
    end

    describe "#validate_types" do
      shared_examples "returns success" do |field, value|
        context "with #{value}" do
          specify do
            result = types_test.validate_types([id: 1, field => value])
            expect(result).to be_nil
          end
        end
      end

      shared_examples "returns error" do |field, value, got|
        context "with #{value}" do
          specify do
            result = types_test.validate_types([id: 1, field => value])
            expect(result[field]).to include("got: #{got}")
          end
        end
      end

      context "Decimal" do
        values = ["1.5", 1.5, 1, "-1.567", BigDecimal("1.5"), Time.current]
        values.each do |value|
          it_behaves_like "returns success", :decimal, value
        end

        it_behaves_like "returns error", :decimal, {}, "Hash"
        it_behaves_like "returns error", :decimal, [], "Array"
        it_behaves_like "returns error", :decimal, "test", "String"
        it_behaves_like "returns error", :decimal, true, "TrueClass"
      end

      context "DateTime" do
        values = [
          "01.01.2010",
          Time.current, Date.current, DateTime.current,
          Sequel::SQLTime.date,
          123, 123.5, BigDecimal("123.5")
        ]
        values.each do |value|
          it_behaves_like "returns success", :datetime, value
        end

        it_behaves_like "returns error", :datetime, {}, "Hash"
        it_behaves_like "returns error", :datetime, [], "Array"
        it_behaves_like "returns error", :datetime, "test", "String"
        it_behaves_like "returns error", :datetime, true, "TrueClass"
        it_behaves_like "returns error", :datetime, 0, "Integer"
        it_behaves_like "returns error", :datetime, 0.1, "Float"
      end

      context "Boolean" do
        values = [
          true, false,
          0, 1,
          "true", "false", "TRUE", "False", "tRuE", "t", "f", "on", "off", "0", "1"
        ]
        values.each do |value|
          it_behaves_like "returns success", :boolean, value
        end

        it_behaves_like "returns error", :boolean, {}, "Hash"
        it_behaves_like "returns error", :boolean, [], "Array"
        it_behaves_like "returns error", :boolean, "test", "String"
        it_behaves_like "returns error", :boolean, 10, "Integer"
        it_behaves_like "returns error", :boolean, -1, "Integer"
        it_behaves_like "returns error", :boolean, 1.5, "Float"
        it_behaves_like "returns error", :boolean, Time.current, "Time"
      end

      context "String" do
        values = [
          true, false,
          "asfdnk", "1.5", "-1", "t", "f", :test,
          BigDecimal(45435), 1, 1.5, -1, 0,
          Time.current, Sequel::SQLTime.date
        ]
        values.each do |value|
          it_behaves_like "returns success", :string, value
        end

        it_behaves_like "returns error", :string, {}, "Hash"
        it_behaves_like "returns error", :string, [], "Array"
        it_behaves_like "returns error", :string, String, "Class"
      end
    end

    describe "transaction and after_commit" do
      let(:checks) { [] }

      before do
        DB[:players].insert(
          external_id: 111,
          project_id: "pid1",
          email: "435",
          online_status: true,
          version: 12.343,
          rest: nil,
        )
      end

      it "fails transaction" do
        begin
          players.transaction do
            result = players.destroy(
              data: [{ external_id: 111, project_id: "pid1", version: 111 }],
              target_keys: %i[external_id project_id],
              version_key: :version,
            )

            expect(result).to eq([{
              external_id: 111,
              project_id: "pid1",
              email: "435",
              online_status: true,
              version: 12.343,
              rest: nil,
              hooks: nil,
            }])

            players.after_commit { checks[0] = "test_after_commit" }
            raise "test error"
          end
        rescue => error
          raise error if error.message != "test error"
        end

        expect(checks).to eq([])
        expect(DB[:players].count).to eq(1)
      end

      it "calls callbacks" do
        players.transaction do
          result = players.destroy(
            data: [{ external_id: 111, project_id: "pid1", version: 111 }],
            target_keys: %i[external_id project_id],
            version_key: :version,
          )

          expect(result).to eq([{
            external_id: 111,
            project_id: "pid1",
            email: "435",
            online_status: true,
            version: 12.343,
            rest: nil,
            hooks: nil,
          }])

          players.after_commit { checks[0] = "test_after_commit" }
        end
        expect(checks).to eq(["test_after_commit"])
        expect(DB[:players].count).to eq(0)
      end
    end
  end
end
