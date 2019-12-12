class AddOAuthLinkFieldsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :oauth_provider, :string
    add_column :users, :oauth_uid, :string
    add_column :users, :oauth_email, :string
  end
end
