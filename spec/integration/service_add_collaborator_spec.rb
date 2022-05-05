# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test AddCollaboratorToUrl service' do
  before do
    wipe_database

    DATA[:accounts].each do |account_data|
      UrlShortener::Account.create(account_data)
    end

    url_data = DATA[:urls].first

    @owner = UrlShortener::Account.all[0]
    @collaborator = UrlShortener::Account.all[1]
    @url = UrlShortener::CreateUrlForOwner.call(
      owner_id: @owner.id, url_data:
    )
  end

  it 'HAPPY: should be able to add a collaborator to a url' do
    UrlShortener::AddCollaboratorToUrl.call(
      email: @collaborator.email,
      url_id: @url.id
    )

    _(@collaborator.urls.count).must_equal 1
    _(@collaborator.urls.first).must_equal @url
  end

  it 'BAD: should not add owner as a collaborator' do
    _(proc {
      UrlShortener::AddCollaboratorToUrl.call(
        email: @owner.email,
        url_id: @url.id
      )
    }).must_raise UrlShortener::AddCollaboratorToUrl::OwnerNotCollaboratorError
  end
end
