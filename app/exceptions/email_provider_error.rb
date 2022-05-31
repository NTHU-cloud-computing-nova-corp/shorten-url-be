# frozen_string_literal: true

module UrlShortener
  module Exceptions
    # Error for invalid registration details
    class EmailProviderError < StandardError
      def initialize(msg = 'Error sending email', exception_type = 'custom')
        @exception_type = exception_type
        super(msg)
      end
    end
  end
end
