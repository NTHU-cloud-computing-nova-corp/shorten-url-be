# frozen_string_literal: true

module UrlShortener
  # Service object to create a new url for an owner
  class CreateUrlForOwner
    def self.call(owner_id:, url_data:)
      Account.find(id: owner_id)
             .add_owned_url(url_data)
    end
  end
end
