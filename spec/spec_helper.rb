# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

require_relative 'test_load_all'

def wipe_database
  UrlShortener::Url.map(&:destroy)
  UrlShortener::Account.map(&:destroy)
end

DATA = {
  accounts: YAML.load(File.read('app/db/seeds/accounts_seed.yml')),
  urls: YAML.load(File.read('app/db/seeds/urls_seed.yml'))
}.freeze
