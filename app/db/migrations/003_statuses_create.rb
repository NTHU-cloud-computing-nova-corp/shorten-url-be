# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:statuses) do
      uuid :id, primary_key: true

      String :code, unique: true, null: false
      String :description

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
