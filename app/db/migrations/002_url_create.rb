# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:urls) do
      uuid :id, primary_key: true
      foreign_key :account_id, table: :accounts, type: :uuid, null: false
      String :password_digest

      String :short_url, unique: true, null: false
      String :long_url, null: false
      String :status_code, null: false, default: 'O'
      String :tags
      String :description

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
