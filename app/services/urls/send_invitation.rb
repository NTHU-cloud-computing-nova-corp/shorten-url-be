# frozen_string_literal: true

require 'http'

module UrlShortener
  module Services
    module Urls

      # srv = UrlShortener::Services::Urls::SendInvitation(sender: "sarunyu.sst@gmail.com", emails: "sarunyu.sst.be@gmail.com", short_url: "PASSW", description: "Share url").call
      ## Send email verfification email
      # params:
      #   - registration: hash with keys :username :email :verification_url
      class SendInvitation
        def initialize(sender, emails, short_url, description, message)
          @sender = sender
          @short_url = short_url
          @emails = emails
          @description = description
          @message = message
        end

        def call
          Services::SendGrid::SendEmail.new.call(mail_json:)
        end

        def full_short_url
          "#{ENV.fetch('APP_URL')}/#{@short_url}"
        end

        def sender_message
          @message.empty? || @message.nil? ? '' : "<B>Message from sender:</B> #{@message}</P>"
        end

        def html_email
          <<~END_EMAIL
            <H3>#{@sender} has invited you to view the shared url: </H3>
            <P><B>Description:</B> #{@description}</P>
            <P><B>Link:</B> <a href=\"#{full_short_url}\">Open link</a></P>
            #{sender_message}
          END_EMAIL
        end

        def email_list_json
          @emails.split(',').map { |e| { email: e } }
        end

        def mail_json # rubocop:disable Metrics/MethodLength
          {
            personalizations: [{
                                 to: email_list_json
                               }],
            from: { 'email' => ENV.fetch('SENDGRID_FROM_EMAIL') },
            subject: 'URL Shortener: Shared link invitation',
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
