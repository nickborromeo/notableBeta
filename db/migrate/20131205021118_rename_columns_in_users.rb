class RenameColumnsInUsers < ActiveRecord::Migration
  def up
		change_table :users do |t|
	    t.rename :current_login_time, :current_sign_in_at
	    t.rename :last_login_time, :last_sign_in_at
	    t.rename :current_login_ip, :current_sign_in_ip
	    t.rename :last_login_ip, :last_sign_in_ip
		end
  end

  def down
		change_table :users do |t|
	    t.rename :current_sign_in_at, :current_login_time
	    t.rename :last_sign_in_at, :last_login_time
	    t.rename :current_sign_in_ip, :current_login_ip
	    t.rename :last_sign_in_ip, :last_login_ip
		end
  end
end

