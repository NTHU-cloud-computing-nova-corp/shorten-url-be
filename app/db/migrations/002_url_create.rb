# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:urls) do
      primary_key :id
      foreign_key :owner_id, :accounts

      String :short_url, unique: true, null: false
      String :long_url, unique: true, null: false
      String :description, unique: true

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
