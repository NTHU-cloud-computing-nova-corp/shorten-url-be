# frozen_string_literal: true

module UrlShortener
  module Exceptions
    # Bad request exception
    class NotFoundError < StandardError
      def initialize(msg = 'Not found', exception_type = 'custom')
        @exception_type = exception_type
        @status_code = 404
        super(msg)
      end
    end
  end
end
