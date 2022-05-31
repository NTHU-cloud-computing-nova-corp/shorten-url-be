# frozen_string_literal: true

require 'http'

module UrlShortener
  module Services
    module Accounts
      ## Send email verfification email
      # params:
      #   - registration: hash with keys :username :email :verification_url
      class SendInvitation
        def initialize(requester, send_information)
          @send_information = send_information
          @requester = requester
        end

        def call
          Services::SendGrid::SendEmail.new.call(mail_json:)
        end

        def html_email
          <<~END_EMAIL
            <H1>#{@requester} shared an url</H1>
            <H3>#{@requester} has invited you to view the shared url: #{@send_information[:description]}</H3>
            <p><a href=\"#{@send_information[:shared_url]}\">Open link</a></p>
          END_EMAIL
        end

        def mail_json # rubocop:disable Metrics/MethodLength
          {
            personalizations: [{
              to: [{ 'email' => @send_information[:email] }]
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
