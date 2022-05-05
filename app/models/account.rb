# frozen_string_literal: true

require 'sequel'
require 'json'
require_relative './password'

module UrlShortener
  # Models a registered account
  class Account < Sequel::Model
    one_to_many :owned_urls, class: :'UrlShortener::Url', key: :owner_id
    many_to_many :collaborations,
                 class: :'UrlShortener::Url',
                 join_table: :accounts_urls,
                 left_key: :collaborator_id, right_key: :url_id

    plugin :association_dependencies,
           owned_urls: :destroy,
           collaborations: :nullify

    plugin :whitelist_security
    set_allowed_columns :username, :email, :password

    plugin :timestamps, update_on_create: true

    def urls
      owned_urls + collaborations
    end

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
          type: 'account',
          attributes: {
            username:,
            email:
          }
        }, options
      )
    end
  end
end
