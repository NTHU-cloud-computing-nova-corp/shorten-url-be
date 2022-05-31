# frozen_string_literal: true

module UrlShortener
  module Exceptions
    # Unauthorized exception
    class ForbiddenError < StandardError
      def initialize(msg = 'Forbidden', exception_type = 'custom')
        @exception_type = exception_type
        @status_code = 403
        super(msg)
      end
    end
  end
end

