class Users::SessionsController < Devise::SessionsController

  def index
  end

  def create
  	super
  	puts "--------Signed in #{current_user.sign_in_count} times -----"
  end

end
