# frozen_string_literal: true

# DB[:items].insert([:a, :b], [1,2])

require 'sequel'
require 'securerandom'
require 'yaml'

STATUSES = YAML.load_file('app/db/constants/statuses_constants.yml')

Sequel.migration do
  up do
    STATUSES.each do |status|
      from(:statuses).insert([:id, :code, :description, :created_at, :updated_at],
                             [SecureRandom.uuid, status['code'], status['description'], Time.now, Time.now])
    end
  end
end
