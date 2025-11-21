# frozen_string_literal: true

require "sequel"
require "active_record"

Sequel.extension :pg_json_ops
DB_NAME = (ENV["DB_NAME"] || "table_sync_test").freeze
db_url = "postgres:///#{DB_NAME}"

`createdb #{DB_NAME} 2> /dev/null`

DB = Sequel.connect(db_url).tap(&:tables)
DB.loggers << Logger.new("log/sequel.log")
Sequel::Model.db.extension(:pg_json)
ActiveRecord::Base.establish_connection(db_url)
ActiveRecord::Base.logger = Logger.new("log/ar.log")

DB.run <<~SQL
  DROP TABLE IF EXISTS "items";
  DROP TABLE IF EXISTS "players";
  DROP TABLE IF EXISTS "clients";
  DROP TABLE IF EXISTS "users";
  DROP TABLE IF EXISTS "stat1";
  DROP TABLE IF EXISTS "stat2";
  DROP TABLE IF EXISTS "types_test";

  DROP TABLE IF EXISTS "custom_schema"."clubs";
  DROP SCHEMA IF EXISTS "custom_schema";

  CREATE TABLE "items" (
    "id" bigserial primary key,
    "name" varchar(255) NOT NULL,
    "price" double precision NOT NULL
  );

  CREATE TABLE "players" (
    "external_id" int primary key,
    "project_id" text,
    "email" varchar(255) NOT NULL,
    "online_status" boolean,
    "version" decimal,
    "rest" jsonb,
    hooks jsonb
  );

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

  CREATE SCHEMA custom_schema;
  CREATE TABLE "custom_schema"."clubs" (
    "id" int primary key,
    "name" text,
    "position" int,
    "version" decimal,
    "rest" jsonb
  );

  CREATE TABLE "stat1" (
    "id" int,
    "value" int,
    "version" decimal,
    PRIMARY KEY (id)
  );

  CREATE TABLE "stat2" (
    "id" int,
    "value" int,
    "version" decimal,
    PRIMARY KEY (id)
  );

  CREATE TABLE "types_test" (
    "id" int,
    "string" text NOT NULL,
    "datetime" timestamp,
    "integer" integer,
    "decimal" decimal,
    "array" text[],
    "boolean" boolean,
    "version" decimal,
    PRIMARY KEY (id)
  );
SQL

RSpec.configure do |config|
  config.before do
    schemas_tables = DB[:pg_tables].where(schemaname: %w[public custom_schema])
                                   .select_hash(:tablename, :schemaname)
    tables = schemas_tables.map { |table, schema| "#{schema}.#{table}" }
    DB.run("TRUNCATE #{tables.join(', ')}")
  end
end

class SequelUser < Sequel::Model(:users)
end

class ARecordUser < ActiveRecord::Base
  self.table_name = "users"
end

class CustomARecordUser < ARecordUser
  def self.table_sync_model_name
    name
  end

  def attributes_for_destroy
    attributes.symbolize_keys
  end

  def attributes_for_sync
    attributes.symbolize_keys
  end

  def attributes_for_headers
    attributes.symbolize_keys
  end

  def attributes_for_routing_key
    attributes.symbolize_keys
  end
end

class CustomSequelUser < SequelUser
  def self.table_sync_model_name
    name
  end

  def attributes_for_destroy
    attributes.symbolize_keys
  end

  def attributes_for_sync
    attributes.symbolize_keys
  end

  def attributes_for_headers
    attributes.symbolize_keys
  end

  def attributes_for_routing_key
    attributes.symbolize_keys
  end
end
