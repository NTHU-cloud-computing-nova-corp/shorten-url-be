# frozen_string_literal: true

require 'roda'
require 'json'
require_relative './helpers'

module UrlShortener
  # Web controller for UrlShortener API
  class Api < Roda
    plugin :halt
    plugin :multi_route
    plugin :request_headers
    plugin :status_303

    include SecureRequestHelpers

    route do |routing|
      response['Content-Type'] = 'application/json'

      secure_request?(routing) ||
        routing.halt(403, { message: 'TLS/SSL Required' }.to_json)

      begin
        @auth_account = authenticated_account(routing.headers)
      rescue AuthToken::InvalidTokenError
        routing.halt 403, { message: 'Invalid auth token' }.to_json
      rescue StandardError
        routing.halt 401, { message: 'Invalid username or password' }.to_json
      end

      routing.root do
        { message: 'UrlShortenerAPI up at /api/v1' }.to_json
      end

      routing.on 'api' do
        routing.on 'v1' do
          @api_root = 'api/v1'
          routing.multi_route
        end
      end

      routing.on String do |short_url|
        # GET
        routing.get do
          url = Url.first(short_url:)
          response.status = 200
          response['Location'] = "#{url.id}"
          { data: url }.to_json
        rescue StandardError => e
          routing.halt 404, { message: e.message }.to_json
        end
      end
    end
  end
end
