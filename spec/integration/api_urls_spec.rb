# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test Url Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
  end

  describe 'Getting urls' do
    it 'HAPPY: should be able to get list of all urls' do
      UrlShortener::Url.create(DATA[:urls][0])
      UrlShortener::Url.create(DATA[:urls][1])

      get 'api/v1/urls'
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result['data'].count).must_equal 2
    end

    it 'HAPPY: should be able to get details of a single url' do
      existing_url = DATA[:urls][1]
      UrlShortener::Url.create(existing_url)
      short_url = UrlShortener::Url.first.short_url

      get "/api/v1/urls/#{short_url}"
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      body = result['data']['attributes']
      _(body['short_url']).must_equal short_url
      _(body['long_url']).must_equal existing_url['long_url']
      _(body['description']).must_equal existing_url['description']
    end

    it 'SAD: should return error if unknown url requested' do
      get '/api/v1/urls/foobar'

      _(last_response.status).must_equal 404
    end

    it 'SECURITY: should prevent basic SQL injection targeting IDs' do
      UrlShortener::Url.create(short_url: 'xxx', long_url: 'long_url')
      UrlShortener::Url.create(short_url: 'NewerUrl', long_url: 'long_url2')
      get 'api/v1/urls/2%20or%20id%3E0'

      # deliberately not reporting error -- don't give attacker information
      _(last_response.status).must_equal 404
      _(last_response.body['data']).must_be_nil
    end
  end

  describe 'Creating New urls' do
    before do
      @req_header = { 'CONTENT_TYPE' => 'application/json' }
      @url_data = DATA[:urls][1]
    end

    it 'HAPPY: should be able to create new urls' do
      post 'api/v1/urls', @url_data.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.header['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']
      url = UrlShortener::Url.first

      _(created['id']).must_equal url.id
      _(created['short_url']).must_equal @url_data['short_url']
      _(created['long_url']).must_equal @url_data['long_url']
      _(created['description']).must_equal @url_data['description']
    end

    it 'SECURITY: should not create url with mass assignment' do
      bad_data = @url_data.clone
      bad_data['created_at'] = '1900-01-01'
      post 'api/v1/urls', bad_data.to_json, @req_header

      _(last_response.status).must_equal 400
      _(last_response.header['Location']).must_be_nil
    end
  end
end
