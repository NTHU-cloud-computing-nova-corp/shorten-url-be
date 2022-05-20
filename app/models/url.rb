# frozen_string_literal: true

require 'json'
require 'sequel'

module UrlShortener
  # Models a url
  class Url < Sequel::Model
    many_to_one :account

    plugin :uuid, field: :id

    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :account_id, :long_url, :short_url, :status_code, :tags, :description

    def to_json(options = {})
      JSON(
        {
          type: 'url',
          attributes: {
            id:,
            long_url:,
            short_url:,
            status_code:,
            tags:,
            description:
          }
        }, options
      )
    end
  end
end
