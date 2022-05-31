# frozen_string_literal: true

require 'http'

module UrlShortener
  module Services
    module SendGrid
      ## Send email verfification email
      # params:
      #   - registration: hash with keys :username :email :verification_url
      class SendEmail
        def from_email = ENV.fetch('SENDGRID_FROM_EMAIL')

        def mail_api_key = ENV.fetch('SENDGRID_API_KEY')

        def mail_url = 'https://api.sendgrid.com/v3/mail/send'

        def call(mail_json:)
          res = HTTP.auth("Bearer #{mail_api_key}")
                    .post(mail_url, json: mail_json)
          raise Exceptions::EmailProviderError if res.status >= 300
        rescue StandardError
          raise(Exceptions::BadRequestError,
                'Could not send verification email; please check email address')
        end
      end
    end
  end
end
