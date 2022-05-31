# frozen_string_literal: true
require 'base64'
require 'rbnacl'

module UrlShortener
  module Services
    module Urls
      # Service object to create a new url for an owner
      class GenerateShortUrl
        def self.call
          valid = false
          until valid
            generated_url = Base64.urlsafe_encode64(RbNaCl::Random.random_bytes(6), padding: false)
            generated_url = generated_url[0..4]
            data = Url.first(short_url: generated_url)
            valid = true if data.nil?
          end

          generated_url
        end
      end
    end
  end
end
