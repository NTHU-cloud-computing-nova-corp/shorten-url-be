# frozen_string_literal: true

module UrlShortener
  module Exceptions
    # Bad request exception
    class DuplicateEntryError < StandardError
      def initialize(msg = 'Duplicate entry', exception_type = 'custom')
        @exception_type = exception_type
        @status_code = 400
        super(msg)
      end
    end
  end
end
