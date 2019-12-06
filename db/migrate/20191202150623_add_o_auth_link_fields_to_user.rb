class AddOAuthLinkFieldsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :oauth_provider, :string, default: true
    add_column :users, :oauth_uid, :string, default: true
    add_column :users, :oauth_email, :string, default: true
  end
end
