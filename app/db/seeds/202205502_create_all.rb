# frozen_string_literal: true

Sequel.seed(:development) do
  def run
    puts 'Seeding accounts, urls, documents'
    create_accounts
    create_accounts_urls
  end
end

require 'yaml'
DIR = File.dirname(__FILE__)
ACCOUNTS_INFO = YAML.load_file("#{DIR}/accounts_seed.yml")
OWNER_INFO = YAML.load_file("#{DIR}/owners_urls.yml")
URL_INFO = YAML.load_file("#{DIR}/urls_seed.yml")

def create_accounts
  ACCOUNTS_INFO.each do |account_info|
    UrlShortener::Account.create(account_info)
  end
end

def create_accounts_urls
  OWNER_INFO.each do |owner|
    account = UrlShortener::Account.first(username: owner['username'])
    owner['urls'].each do |short_url|
      url_data = URL_INFO.find { |url| url['short_url'] == short_url }
      UrlShortener::CreateUrlForAccount.call(
        account_id: account.id, url: url_data
      )
    end
  end
end

