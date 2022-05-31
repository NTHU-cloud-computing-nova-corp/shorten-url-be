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

    def check_authentication(routing)
      begin
        @auth_account = authenticated_account(routing.headers)
      rescue AuthToken::InvalidTokenError
        routing.halt 403, { message: 'Invalid auth token' }.to_json
      rescue StandardError
        routing.halt 401, { message: 'Invalid username or password' }.to_json
      end
    end

    route do |routing|
      response['Content-Type'] = 'application/json'

      secure_request?(routing) ||
        routing.halt(403, { message: 'TLS/SSL Required' }.to_json)

      routing.root do
        { message: 'UrlShortenerAPI up at /api/v1' }.to_json
      end

      routing.on 'api' do
        check_authentication(routing)
        routing.on 'v1' do
          @api_root = 'api/v1'
          routing.multi_route
        end
      end

      routing.on String do |short_url|
        @url = Url.first(short_url:)
        # POST /:short_url/unlock :: Unlock an url
        routing.post 'unlock' do
          password_body = JSON.parse(routing.body.read)
          raise unless @url.password?(password_body['password'])

          response.status = 200
          response['Location'] = "/#{short_url}/unlock"
          { message: 'Url is unlocked', data: @url }.to_json
        end
        # GET
        routing.get do
          case @url[:status_code]
          when 'O', 'L'
            puts "Open"
          when 'S', 'P'
            check_authentication(routing)
          else
            routing.halt 403, { message: 'Invalid credentials' }.to_json
          end

          response.status = 200
          response['Location'] = "/#{short_url}"
          { data: @url, status: 200 }.to_json
        rescue StandardError => e
          routing.halt 404, { message: e.message }.to_json
        end
      end

    rescue Sequel::MassAssignmentRestriction => e
      Api.logger.warn "MASS-ASSIGNMENT: #{e.message}"
      routing.halt 400, { message: 'Illegal Attributes' }.to_json
    rescue Exceptions::NotFoundError, Exceptions::BadRequestError,
           Exceptions::ForbiddenError, JSON::ParserError => e
      status_code = e.instance_variable_get(:@status_code)
      routing.halt status_code, { code: status_code, message: "Error: #{e.message}" }.to_json
    rescue StandardError => e
      case e
      when Sequel::UniqueConstraintViolation
        status_code = 400
        error_message = e.wrapped_exception
        Api.logger.error e.message
      else
        error_message = 'Error : Unknown server error'
        status_code = 500
        Api.logger.error "UNKNOWN ERROR: #{e.message}"
      end
      routing.halt status_code, { code: status_code, message: error_message }.to_json
    end
  end
end
