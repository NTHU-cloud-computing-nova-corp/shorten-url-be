# frozen_string_literal: true

require 'sequel'
require 'json'
require_relative './password'

module UrlShortener
  # Models a registered account
  class Account < Sequel::Model
    one_to_many :urls

    plugin :association_dependencies, urls: :destroy

    plugin :uuid, field: :id
    plugin :whitelist_security
    set_allowed_columns :username, :email, :password

    plugin :timestamps, update_on_create: true

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
