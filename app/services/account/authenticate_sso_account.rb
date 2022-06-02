# frozen_string_literal: true

module UrlShortener
  module Services
    module Accounts
      # Find account and check password
      class AuthenticateSSO
        # Error for invalid credentials
        class UnauthorizedError < StandardError
          def initialize(msg = nil)
            super
            @credentials = msg
          end

          def message
            "Invalid Credentials for: #{@credentials[:username]}"
          end
        end

        def self.call(credentials)
          client = Signet::OAuth2::Client.new(access_token: credentials[:access_token])
          service = Google::Apis::GmailV1::GmailService.new
          service.authorization = client
          account_info = service.get_user_profile('me')
          account_and_token(sso_account(email: account_info.email_address))
        rescue StandardError => e
          Api.logger.error "Could not create sso account: #{e.inspect}"

          raise(UnauthorizedError, credentials)
        end

        def self.sso_account(email:)
          account = Account.first(email: email)
          if account.nil?
            account = Account.new
            account[:email] = email
            account[:username] = email
            account.save
          end
          account
        end

        def self.account_and_token(account)
          {
            type: 'authenticated_account',
            attributes: {
              account:,
              auth_token: AuthToken.create(account)
            }
          }
        end
      end
    end
  end
end
