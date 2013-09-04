class UsersController < ApplicationController
  respond_to :json
  before_filter :admin_user,     only: [:destroy, :index]

  def index
    @users = User.all
  end

  def create
=begin
    @user = User.new(params[:user])
    if @user.save
      flash[:success] = "Welcome to Notable!"
      sign_in @user      
      redirect_to root_path
    else
      render 'new'
    end
=end
  end

  def new
    @user = User.new
  end

  def show
    # @user = User.find(params[:id])
    # @notes = @user.notes
  end

  def edit
  end

  def update
  end

  def destroy
=begin
    User.find(params[:id]).destroy
    flash[:success] = "User successfully removed."
    redirect_to users_url
=end
  end

  private
    def admin_user
      # redirect_to(root_path) unless current_user.admin?
    end

end
