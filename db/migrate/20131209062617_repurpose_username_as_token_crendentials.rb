class RepurposeUsernameAsTokenCrendentials < ActiveRecord::Migration
  def up
  	rename_column :users, :username, :token_credentials
  end

  def down
  	rename_column :users, :token_credentials, :username
  end
end
