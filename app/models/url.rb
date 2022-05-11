# frozen_string_literal: true

require 'json'
require 'sequel'

module UrlShortener
  # Models a url
  class Url < Sequel::Model
    many_to_one :owner, class: :'UrlShortener::Account'

    many_to_many :collaborators,
                 class: :'UrlShortener::Account',
                 join_table: :accounts_urls,
                 left_key: :url_id, right_key: :collaborator_id

    plugin :association_dependencies,
           collaborators: :nullify

    plugin :timestamps
    plugin :whitelist_security
    set_allowed_columns :owner_id, :long_url, :short_url, :description

    def to_json(options = {})
      JSON(
        {
          type: 'url',
          attributes: {
            id:,
            long_url:,
            short_url:,
            description:
          }
        }, options
      )
    end
  end
end
