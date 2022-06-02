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
      end
    end

    def check_shared_email(routing, url)

      check_authentication(routing)
      raise Exceptions::ForbiddenError if @auth_account.nil?

      account = Account.first(username: @auth_account['username'])
      if Url.first(id: url[:id], account_id: account[:id]).nil? &&
         EmailUrl.first(url_id: url[:id], email: account[:email]).nil?
        raise Exceptions::ForbiddenError, "You don't have permission for this URL"
      end
    end

    def check_private_email(routing, short_url)
      check_authentication(routing)
      raise Exceptions::ForbiddenError if @auth_account.nil?

      account = Account.first(username: @auth_account['username'])
      raise Exceptions::ForbiddenError if account.urls.find(short_url:).first.nil?
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
            puts 'Open'
          when 'S'
            check_shared_email(routing, @url)
          when 'P'
            check_private_email(routing, @url)
          else
            routing.halt 403, { message: 'Invalid credentials' }.to_json
          end

          response.status = 200
          response['Location'] = "/#{short_url}"
          { data: @url, status: 200 }.to_json
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
