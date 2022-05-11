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
          routing.halt(404, { message: 'Could not find documents' }.to_json)
        end
      end

      # GET api/v1/urls
      routing.get do
        output = { data: Url.all }
        JSON.pretty_generate(output)
      rescue StandardError
        routing.halt 404, { message: 'Could not find urls' }.to_json
      end

      # POST api/v1/urls
      routing.post do
        new_data = JSON.parse(routing.body.read)
        new_data['short_url'] = UrlShortener::GenerateShortUrl.call
        new_proj = Url.new(new_data)

        raise('Could not save url') unless new_proj.save

        response.status = 201
        response['Location'] = "#{@proj_route}/#{new_proj.id}"
        { message: 'URL saved', data: new_proj }.to_json
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
