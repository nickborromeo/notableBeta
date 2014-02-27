class UpgradeController < ApplicationController

  def pricing
  end

  def checkout
  end

  def delivery
  end

  def danger
    @users = User.order("email")
  end

  def ultra
  	puts "ultra----------------------"
  	blanket = params[:id]
  	User.find(params[:id]).destroy
    redirect_to custom_thing_url
    flash[:success] = "User #{blanket} successfully removed."
  end

end
