# frozen_string_literal: true

module UrlShortener
  module Exceptions
    # Unauthorized exception
    class UnauthorizedError < StandardError
      def initialize(msg = nil)
        super
        @credentials = msg
        @status_code = 401
      end

      def message
        "Invalid Credentials for: #{@credentials[:username]}"
      end
    end
  end
end
