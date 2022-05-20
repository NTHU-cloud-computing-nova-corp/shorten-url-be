# frozen_string_literal: true

require 'roda'
require_relative './app'

module UrlShortener
  # Web controller for UrlShortener API
  class Api < Roda
    # rubocop:disable Metrics/BlockLength
    route('urls') do |routing|
      @url_route = "#{@api_root}/urls"

      routing.on String do |short_url|
        # GET api/v1/urls/[proj_id]/documents
        routing.get do
          data = Url.first(short_url:)
          raise StandardError if data.nil?

          output = { data: }
          JSON.pretty_generate(output)
        rescue StandardError
          routing.halt(404, { message: 'Could not find Url' }.to_json)
        end

        routing.post 'delete' do
          raise('Could not delete Url') unless Url.where(short_url:).delete

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/delete"
          { message: 'Url has been deleted' }.to_json
        end
      end

      # GET api/v1/urls
      routing.get do
        account = Account.first(username: @auth_account['username'])
        output = { data: Url.where(account_id: account.id).all }
        JSON.pretty_generate(output)
      rescue StandardError
        routing.halt 404, { message: 'Could not find urls' }.to_json
      end

      # POST api/v1/urls
      routing.post do
        account = Account.first(username: @auth_account['username'])

        new_data = JSON.parse(routing.body.read)
        new_data['short_url'] = UrlShortener::GenerateShortUrl.call
        new_data['account_id'] = account.id
        url = Url.new(new_data)
        raise('Could not save url') unless url.save

        response.status = 200
        url.to_json
      rescue Sequel::MassAssignmentRestriction
        Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
        routing.halt 400, { message: 'Illegal Attributes' }.to_json
      rescue StandardError => e
        Api.logger.error "UNKOWN ERROR: #{e.message}"
        routing.halt 500, { message: 'Unknown server error' }.to_json
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
