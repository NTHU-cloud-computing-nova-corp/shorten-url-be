# frozen_string_literal: true

require 'json'
require 'sequel'

module UrlShortener
  # Models a url
  class EmailUrl < Sequel::Model
    many_to_one :urls, class: :'UrlShortener::Url', key: :url_id
    plugin :uuid, field: :id

    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :url_id, :email

    def to_json(options = {})
      JSON(
        {
          type: 'email_url',
          attributes: {
            url_id:,
            email:
          }
        }, options
      )
    end
  end
end
