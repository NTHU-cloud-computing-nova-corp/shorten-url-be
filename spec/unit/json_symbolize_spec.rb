# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test JsonRequestBody symbolizing' do
  it 'HAPPY: should symbolize jsonified hashes' do
    correct_hash = { username: 'testuser', password: 'testpass' }
    json = correct_hash.to_json

    _(JSON.parse(json)).wont_equal correct_hash
    _(JsonRequestBody.parse_symbolize(json)).must_equal correct_hash
  end
end
