# frozen_string_literal: true

require_relative './app'

# General UrlShortener module
module UrlShortener
  # Web controller for UrlShortener API, properties sub-route
  class Api < Roda
    route('statuses') do |routing|
      # GET api/v1/statuses
      # Get all statuses
      routing.get do
        output = { data: UrlShortener::Status.all }
        JSON.pretty_generate(output)
      end
    end
  end
end
