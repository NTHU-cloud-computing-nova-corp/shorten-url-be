# frozen_string_literal: true

require 'json'
require 'sequel'

module UrlShortener
  # Models a propertyType
  class Status < Sequel::Model
    plugin :uuid, field: :id
    plugin :whitelist_security

    # rubocop:disable Metrics/MethodLength
    def to_json(options = {})
      JSON(
        {
          data: {
            type: 'status',
            attributes: {
              id:,
              code:,
              description:
            }
          }
        }, options
      )
    end

    # rubocop:enable Metrics/MethodLength
  end
end
