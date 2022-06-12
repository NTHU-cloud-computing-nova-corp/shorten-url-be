# frozen_string_literal: true

require 'roda'
require_relative './app'

module UrlShortener
  # Web controller for UrlShortener API
  class Api < Roda
    # rubocop:disable Metrics/BlockLength
    route('urls') do |routing|
      @account = Account.first(username: @auth_account['username'])
      @url_route = "#{@api_root}/urls"

      routing.get 'shared_urls' do
        urls = UrlShortener::EmailUrl.where(email: @account[:email]).all
        urls = urls.map do |u|
          url = u.urls

          { id: url[:id], long_url: url[:long_url],
            short_url: url[:short_url], status_code: url[:status_code],
            description: url[:description], tags: url[:tags].nil? ? '' : url[:tags] }
        end
        url_list = urls.select { |l| l[:status_code] == 'S' }
        JSON.pretty_generate({ data: url_list })
      end

      routing.on String do |short_url|
        @url = Url.first(short_url:, account_id: @account[:id])
        raise Exceptions::NotFoundError if @url.nil?

        # GET api/v1/urls/:short_url :: Get an url
        routing.get do
          output = { data: @url }
          JSON.pretty_generate(output)
        rescue StandardError
          routing.halt(404, { message: 'Could not find Url' }.to_json)
        end

        # POST api/v1/urls/:short_url/open :: Open an url
        routing.post 'open' do
          @url.update(status_code: 'O')

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/open"
        end

        # POST api/v1/urls/:short_url/lock :: Lock an url
        routing.post 'lock' do
          updated_data = JSON.parse(routing.body.read)
          raise StandardError unless @url.update(status_code: 'L', password: updated_data['password'])

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/lock"
        end

        # POST api/v1/urls/:short_url/privatise :: Privatise an url
        routing.post 'privatise' do
          @url.update(status_code: 'P')

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/privatise"
        end

        # POST api/v1/urls/:short_url/share :: Share an url
        routing.post 'share' do
          @url.update(status_code: 'S')

          updated_data = JSON.parse(routing.body.read)
          EmailUrl.where(url_id: @url[:id]).delete
          updated_data['emails'].split(',').each do |email|
            email = @url.add_shared_email(email:)
            raise StandardError unless email.save
          end

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/share"
          { message: 'Url is shared' }.to_json
        end

        routing.post 'invite' do
          request_data = JSON.parse(routing.body.read)
          emails = request_data['emails']
          Services::Urls::SendInvitation.new(@account[:email], emails, short_url, @url[:description],
                                             request_data['message']).call

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/invite"
          { message: 'Emails invited' }.to_json
        end

        # POST api/v1/urls :: Update an url
        routing.post 'update' do
          updated_data = JSON.parse(routing.body.read)
          raise(updated_data.keys.to_s) unless @url.update(updated_data)

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/update"
          { message: 'Url is updated', data: updated_data }.to_json
        end

        # POST api/v1/urls/:short_url/delete :: Delete an url
        routing.post 'delete' do
          raise('Could not delete Url') unless EmailUrl.where(url_id: @url[:id]).delete
          raise('Could not delete Url') unless @url.delete

          response.status = 200
          response['Location'] = "#{@url_route}/#{short_url}/delete"
          { message: 'Url has been deleted' }.to_json
        end
      end

      # GET api/v1/urls
      routing.get do
        output = { data: UrlShortener::Url.where(account_id: @account[:id]).order(Sequel.desc(:updated_at)).all }
        JSON.pretty_generate(output)
      rescue StandardError
        routing.halt 404, { message: 'Could not find urls' }.to_json
      end

      # POST api/v1/urls :: Creating a new url
      routing.post do
        new_data = JSON.parse(routing.body.read)
        new_data['short_url'] = Services::Urls::GenerateShortUrl.call
        url = @account.add_url(new_data)
        raise('Could not save url') unless url.save

        response.status = 201
        response['Location'] = @url_route.to_s

        { message: 'Url saved', data: url }.to_json
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
