# frozen_string_literal: true

require 'json'
require 'sequel'

module UrlShortener
  # Models a url
  class Url < Sequel::Model
    many_to_one :account
    one_to_many :shared_emails, class: :'UrlShortener::EmailUrl', key: :url_id

    plugin :uuid, field: :id

    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :password, :account_id, :long_url, :short_url, :status_code, :tags, :description

    def password=(new_password)
      self.password_digest = Password.digest(new_password)
    end

    def password?(try_password)
      digest = UrlShortener::Password.from_digest(password_digest)
      digest.correct?(try_password)
    end

    def to_json(options = {})
      JSON(
        {
          type: 'url',
          attributes: {
            id:,
            long_url:,
            short_url:,
            status_code:,
            tags: tags.nil? ? '' : tags,
            description:,
            shared_email_list:
          }
        }, options
      )
    end

    def shared_email_list
      emails = shared_emails.map do |email|
        email[:email]
      end
      emails.nil? ? '' : emails.join(',')
    end
  end
end
