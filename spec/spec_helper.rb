# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

require_relative 'test_load_all'

def wipe_database
  UrlShortener::EmailUrl.dataset.destroy
  UrlShortener::Account.dataset.destroy
  UrlShortener::Url.dataset.destroy
end

def seed_accounts
  DATA[:accounts].each do |account|
    UrlShortener::Account.create(account)
  end
end

def seed_urls
  DATA[:accounts].each do |owner|
    account = UrlShortener::Account.first(username: owner['username'])
    owner['urls'].each do |short_url|
      url_data = URL_INFO.find { |url| url['short_url'] == short_url }
      UrlShortener::Services::Urls::CreateUrlForAccount.call(
        account_id: account.id, url: url_data
      )
    end
  end
end

DATA = {
  accounts: YAML.load(File.read('app/db/seeds/accounts_seed.yml')),
  urls: YAML.load(File.read('app/db/seeds/urls_seed.yml'))
}.freeze
