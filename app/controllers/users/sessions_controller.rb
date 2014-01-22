class Users::SessionsController < Devise::SessionsController
  respond_to :json

	def index
		# @user = User.where("id = " + current_user.id)
		# respond_With(@user)
		respond_with(current_user)
	end

	def create
		super
		if current_user.sign_in_count%14 == 0
			flash[:notice] = %Q[Have you tried Notable premium? <a href="pricing">Upgrade today to redeem a 50% discount!</a>].html_safe
		end
	end

  def update
    @user = User.find(params[:id])
    @user.update_attributes(params[:session])
    head :no_content
  end

end
