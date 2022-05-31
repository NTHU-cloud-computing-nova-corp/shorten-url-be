# frozen_string_literal: true

require 'http'

module UrlShortener
  module Services
    module Accounts
      ## Send email verfification email
      # params:
      #   - registration: hash with keys :username :email :verification_url
      class VerifyRegistration
        # Error for invalid registration details
        class InvalidRegistration < StandardError; end

        class EmailProviderError < StandardError; end

        def initialize(registration)
          @registration = registration
        end

        def call
          raise(InvalidRegistration, 'Username exists') unless username_available?
          raise(InvalidRegistration, 'Email already used') unless email_available?

          Services::SendGrid::SendEmail.new.call(mail_json:)
        end

        def username_available?
          Account.first(username: @registration[:username]).nil?
        end

        def email_available?
          Account.first(email: @registration[:email]).nil?
        end

        def html_email
          <<~END_EMAIL
            <H1>URL Shortener Registration Received</H1>
            <p>Please <a href=\"#{@registration[:verification_url]}\">click here</a>
            to validate your email.
            You will be asked to set a password to activate your account.</p>
          END_EMAIL
        end

        def mail_json # rubocop:disable Metrics/MethodLength
          {
            personalizations: [{
                                 to: [{ 'email' => @registration[:email] }]
                               }],
            from: { 'email' => ENV.fetch('SENDGRID_FROM_EMAIL') },
            subject: 'URL Shortener Registration Verification',
            content: [
              { type: 'text/html',
                value: html_email }
            ]
          }
        end
      end
    end
  end
end
