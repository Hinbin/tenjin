# frozen_string_literal: true

# Account lookup and Google OAuth2 account-linking for users. Extracted from User to keep the model
# focused; behaviour is unchanged.
module OauthLinkable
  extend ActiveSupport::Concern

  class_methods do
    def from_omniauth(auth, current_user = nil)
      user = find_by(provider: auth['provider'], upi: auth['upi'])
      user = find_by(oauth_provider: auth['provider'], oauth_uid: auth['uid']) if user.nil?

      return user if user.present?

      # If signed in and its an oauth2 google request, assume linking of accounts
      return unless auth['provider'] == 'google_oauth2' && current_user.present?

      save_oauth_user_details(auth, current_user)
    end

    def save_oauth_user_details(auth, current_user)
      return unless auth['info'].present?

      current_user.oauth_uid = auth['uid']
      current_user.oauth_provider = auth['provider']
      current_user.oauth_email = auth['info']['email']
      current_user.save
      current_user
    end

    def unlink_account
      current_user.oauth_uid = ''
      current_user.oauth_provider = ''
      current_user.save
    end
  end
end
