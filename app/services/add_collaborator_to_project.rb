# frozen_string_literal: true

module UrlShortener
  # Add a collaborator to another owner's existing url
  class AddCollaboratorToUrl
    # Error for owner cannot be collaborator
    class OwnerNotCollaboratorError < StandardError
      def message = 'Owner cannot be collaborator of url'
    end

    def self.call(email:, url_id:)
      collaborator = Account.first(email:)
      url = Url.first(id: url_id)
      raise(OwnerNotCollaboratorError) if url.owner.id == collaborator.id

      url.add_collaborator(collaborator)
    end
  end
end
