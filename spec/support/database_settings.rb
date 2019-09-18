# frozen_string_literal: true

require "sequel"
require "active_record"

Sequel.extension :pg_json_ops
DB_NAME = (ENV["DB_NAME"] || "table_sync_test").freeze
db_url = "postgres:///#{DB_NAME}"

def connect(db_url)
  Sequel.connect(db_url).tap(&:tables)
rescue Sequel::DatabaseConnectionError => error
  raise unless error.message.include? "database \"#{DB_NAME}\" does not exist"

  `createdb #{DB_NAME}`
  Sequel.connect(db_url)
end

DB = connect(db_url)
DB.loggers << Logger.new("log/sequel.log")
Sequel::Model.db.extension(:pg_json)
ActiveRecord::Base.establish_connection(db_url)
ActiveRecord::Base.logger = Logger.new("log/ar.log")

DB.run <<~SQL
  DROP TABLE IF EXISTS "items";
  CREATE TABLE "items" (
    "id" bigserial primary key,
    "name" varchar(255) NOT NULL,
    "price" double precision NOT NULL
  );

  DROP TABLE IF EXISTS "players";
  CREATE TABLE "players" (
    "external_id" int primary key,
    "project_id" text,
    "email" varchar(255) NOT NULL,
    "online_status" boolean,
    "version" decimal,
    "rest" jsonb
  );

  DROP TABLE IF EXISTS "simple_players";
  CREATE TABLE "simple_players" (
    "external_id" int,
    "internal_id" int,
    "project_id" text,
    "version" decimal,
    "rest" jsonb,
    PRIMARY KEY (external_id, internal_id)
  );

  DROP TABLE IF EXISTS "players_part_1";
  CREATE TABLE "players_part_1" (like "players" INCLUDING ALL);

  DROP TABLE IF EXISTS "clients";
  CREATE TABLE "clients" (
    "client_id" int,
    "project_id" int,
    "name" varchar(255) NOT NULL,
    "ext_id" int NOT NULL,
    "ext_project_id" int NOT NULL,
    "ts_version" decimal,
    "ts_rest" jsonb,
    PRIMARY KEY (client_id, project_id),
    UNIQUE (ext_id, ext_project_id)
  );

  DROP TABLE IF EXISTS "users";
  CREATE TABLE "users" (
    "id" int primary key,
    "name" varchar(255) NOT NULL,
    "email" varchar(255) NOT NULL,
    "ext_id" int NOT NULL,
    "ext_project_id" int NOT NULL,
    "version" decimal,
    "rest" jsonb,
    "first_sync_time" timestamp without time zone,
    UNIQUE (ext_id, ext_project_id)
  );

  DROP TABLE IF EXISTS "custom_schema"."clubs";
  DROP SCHEMA IF EXISTS "custom_schema";

  CREATE SCHEMA custom_schema;
  CREATE TABLE "custom_schema"."clubs" (
    "id" int primary key,
    "name" text,
    "position" int,
    "version" decimal,
    "rest" jsonb
  );
SQL

RSpec.configure do |config|
  config.before do
    schemas_tables = DB[:pg_tables].where(schemaname: %w[public custom_schema]).select_hash(:tablename, :schemaname)
    tables = schemas_tables.map { |table, schema| "#{schema}.#{table}" }
    DB.run("TRUNCATE #{tables.join(', ')}")
  end
end
