# frozen_string_literal: true

Sequel.seed(:development) do
  def run
    puts 'Seeding accounts, urls, documents'
    create_accounts
    create_owned_urls
    add_collaborators
  end
end

require 'yaml'
DIR = File.dirname(__FILE__)
ACCOUNTS_INFO = YAML.load_file("#{DIR}/accounts_seed.yml")
OWNER_INFO = YAML.load_file("#{DIR}/owners_urls.yml")
URL_INFO = YAML.load_file("#{DIR}/urls_seed.yml")
CONTRIB_INFO = YAML.load_file("#{DIR}/urls_collaborators.yml")

def create_accounts
  ACCOUNTS_INFO.each do |account_info|
    UrlShortener::Account.create(account_info)
  end
end

def create_owned_urls
  OWNER_INFO.each do |owner|
    account = UrlShortener::Account.first(username: owner['username'])
    owner['urls'].each do |short_url|
      url_data = URL_INFO.find { |url| url['short_url'] == short_url }
      UrlShortener::CreateUrlForOwner.call(
        owner_id: account.id, url_data:
      )
    end
  end
end

def add_collaborators
  contrib_info = CONTRIB_INFO
  contrib_info.each do |contrib|
    url = UrlShortener::Url.first(short_url: contrib['short_url'])
    contrib['collaborator_email'].each do |email|
      UrlShortener::AddCollaboratorToUrl.call(email:, url_id: url.id)
    end
  end
end
