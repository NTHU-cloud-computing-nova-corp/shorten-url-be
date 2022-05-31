# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:email_urls) do
      uuid :id, primary_key: true

      foreign_key :url_id, table: :urls, type: :uuid, null: false
      String :email, null: false

      unique [:url_id, :email]
    end
  end
end
