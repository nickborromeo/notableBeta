class UsersController < Devise::RegistrationsController
  respond_to :json
  before_filter :admin_user,     only: [:destroy, :index]

  def index
    # @users = User.all
  end

  def show
    super
    # @user = User.find(params[:id])
    # @notes = @user.notes
  end

  def create
    super
=begin
    @email = params[:email]

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
    super
  end

  def edit
    super
  end

  def update
    super
  end

  def destroy
    super
=begin
    User.find(params[:id]).destroy
    flash[:success] = "User successfully removed."
    redirect_to users_url
=end
  end

  def cancel
    super
  end

  private
    def admin_user
      # redirect_to(root_path) unless current_user.admin?
    end

end
