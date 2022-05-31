# frozen_string_literal: true

module UrlShortener
  module Services
    module Urls
      # Service object to create a new property for an account
      class CreateUrlForAccount
        def self.call(account_id:, url:)
          Account.find(id: account_id)
                 .add_url(url)
        end
      end
    end
  end
end
