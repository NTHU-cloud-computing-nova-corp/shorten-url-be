# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test Url Handling' do
  include Rack::Test::Methods

  def login_account(account)
    @account_data = account

    @auth = UrlShortener::Services::Accounts::Authenticate.call(
      username: @account_data['username'],
      password: @account_data['password']
    )
    header 'AUTHORIZATION', "Bearer #{@auth[:attributes][:auth_token]}"
    @req_header = { 'CONTENT_TYPE' => 'application/json' }
    @owner = UrlShortener::Account.first
  end

  before(:each) do
    wipe_database
    seed_accounts
    login_account(DATA[:accounts][0])
    @url_data = DATA[:urls][1]
    @owner.add_url(DATA[:urls][2])
    @url = @owner.urls.first
  end

  describe 'GET api/v1/urls :: Getting urls' do
    it 'HAPPY: should be able to get list of all urls' do
      @owner.add_url(DATA[:urls][0])
      @owner.add_url(DATA[:urls][1])

      get 'api/v1/urls'
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result['data'].count).must_equal 3
    end
  end
  describe 'GET api/v1/urls/:shorten_url :: Getting an url' do
    it 'HAPPY: should be able to get details of a single url' do
      existing_url = @owner.add_url(DATA[:urls][1])

      get "/api/v1/urls/#{existing_url[:short_url]}"
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      body = result['data']['attributes']
      _(body['short_url']).must_equal existing_url[:short_url]
      _(body['long_url']).must_equal existing_url[:long_url]
      _(body['description']).must_equal existing_url[:description]
    end

    it 'SAD: should return error if unknown url requested' do
      get '/api/v1/urls/foobar'

      _(last_response.status).must_equal 404
    end

    it 'SECURITY: should prevent basic SQL injection targeting IDs' do
      @owner.add_url(short_url: 'xxx', long_url: 'long_url', status_code: 'O')
      @owner.add_url(short_url: 'NewerUrl', long_url: 'long_url2', status_code: 'O')
      get 'api/v1/urls/2%20or%20id%3E0'

      # deliberately not reporting error -- don't give attacker information
      _(last_response.status).must_equal 404
      _(last_response.body['data']).must_be_nil
    end
  end
  describe 'POST api/v1/urls :: Creating a new url' do
    it 'HAPPY: should be able to create new urls' do
      new_url = @url_data.clone
      new_url['long_url'] = 'my_new_url.com'
      new_url['description'] = 'new url description'
      post 'api/v1/urls', new_url.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.header['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']

      _(created['short_url']).wont_be_nil
      _(created['long_url']).must_equal new_url['long_url']
      _(created['description']).must_equal new_url['description']
    end

    it 'SECURITY: should not create url with mass assignment' do
      # given
      bad_data = @url_data.clone
      bad_data['created_at'] = '1900-01-01'

      # when
      post 'api/v1/urls', bad_data.to_json, @req_header

      # then
      _(last_response.status).must_equal 400
      _(last_response.header['Location']).must_be_nil
    end
  end
  describe 'POST api/v/urls/:short_url/open :: Open an url' do
    it 'HAPPY: should be able to open url' do
      # given
      @url.update(status_code: 'P')

      # when
      post "api/v1/urls/#{@url[:short_url]}/open", {}, @req_header

      # then
      _(last_response.status).must_equal 200
      @url.refresh
      _(@url.status_code).must_equal 'O'
    end
  end
  describe 'POST api/v1/urls/:short_url/lock :: Lock an url' do
    it 'HAPPY: should be able to open url' do
      # given
      @url.update(status_code: 'O')

      # when
      post "api/v1/urls/#{@url[:short_url]}/lock", { password: '123456' }.to_json, @req_header

      # then
      _(last_response.status).must_equal 200
      @url.refresh
      _(@url.status_code).must_equal 'L'
    end
  end
  describe 'POST :short_url/unlock :: Unlock an url' do
    it 'HAPPY: should be able to open url' do
      # given
      @url.update(status_code: 'O')
      post "api/v1/urls/#{@url[:short_url]}/lock", { password: '123456' }.to_json, @req_header

      # when
      post "#{@url[:short_url]}/unlock", { password: '123456' }.to_json, @req_header

      # then
      _(last_response.status).must_equal 200
      result = JSON.parse last_response.body
      body = result['data']['attributes']
      _(body['status_code']).must_equal 'L'
      _(body['short_url']).must_equal @url[:short_url]
    end
  end
  describe 'POST api/v1/urls/:short_url/privatise :: Privatise an url' do
    it 'HAPPY: should be able to open url' do
      # given
      @url.update(status_code: 'O')

      # when
      post "api/v1/urls/#{@url[:short_url]}/privatise", {}, @req_header

      # then
      _(last_response.status).must_equal 200
      @url.refresh
      _(@url[:status_code]).must_equal 'P'
    end
  end
  describe 'POST api/v1/urls/:short_url/share :: Share an url' do
    it 'HAPPY: should be able to share url' do
      # given
      @url.update(status_code: 'O')
      emails = 'ddd@g1.com,ddd@g2.com,ddd@g3.com'
      spited_emails = emails.split(',')

      # when
      post "api/v1/urls/#{@url[:short_url]}/share", { emails: }.to_json, @req_header

      # then
      _(last_response.status).must_equal 200
      @url.refresh
      _(@url[:status_code]).must_equal 'S'
      _(@url.shared_emails.length).must_equal spited_emails.length
      _(@url.shared_emails[0][:email]).must_equal spited_emails[0]
      _(@url.shared_emails[1][:email]).must_equal spited_emails[1]
      _(@url.shared_emails[2][:email]).must_equal spited_emails[2]
    end
  end
  describe 'POST api/v1/urls/:short_url/invite :: Invite emails' do
    it 'HAPPY: should be able to invite emails for an url' do
      # given
      @url.update(status_code: 'S')
      # emails = 'sarunyu.sst@gmail.com,sarunyu.sst.be@gmail.com'
      emails = 'sarunyu.sst@gmail.com'
      message = 'Hello from Ernesto!'

      # when
      post "api/v1/urls/#{@url[:short_url]}/invite", { emails:, message: }.to_json, @req_header

      # then
      _(last_response.status).must_equal 200
    end
  end
  describe 'POST api/v1/urls :: Update an url' do
    # it 'HAPPY: should be able to update a url' do
    #   updated_url = @url_data.clone
    #   updated_url[:long_url] = 'www.updated.com'
    #   updated_url[:description] = 'updated description'
    #
    #   post "api/v1/urls/#{@url[:short_url]}/update", updated_url.to_json, @req_header
    #   _(last_response.status).must_equal 200
    #   _(last_response.header['Location'].size).must_be :>, 0
    #
    #   updated_data = JSON.parse(last_response.body)['data']
    #
    #   _(updated_data['id']).must_equal updated_url[:id]
    #   _(updated_data['short_url']).wont_be_nil
    #   _(updated_data['long_url']).must_equal updated_url[:long_url]
    #   _(updated_data['description']).must_equal updated_url[:description]
    # end
  end
  describe 'POST api/v1/urls/:short_url/update :: Delete an url' do
    it 'HAPPY: should be able to share url' do
      # given
      deleted_url = @url[:short_url]

      # when
      post "api/v1/urls/#{deleted_url}/delete", {}, @req_header

      # then
      _(last_response.status).must_equal 200
      _(UrlShortener::Url.first(short_url: deleted_url)).must_be_nil
    end
  end
end
