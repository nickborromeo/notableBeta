class Users::SessionsController < Devise::SessionsController

  def index
  end

  def create
  	super
  	puts "---------- create session from SessionsController ---------"
  end

end
