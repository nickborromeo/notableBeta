class Users::SessionsController < Devise::SessionsController

	def index
	end

	def create
		super
		if current_user.sign_in_count%14 == 0
			flash[:notice] = %Q[Have you tried Notable premium? <a href="pricing">Upgrade today to redeem a 50% discount!</a>].html_safe
		end
	end

end
