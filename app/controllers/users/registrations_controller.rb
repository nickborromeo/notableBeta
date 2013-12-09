class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  before_filter :admin_user,     only: [:destroy, :index]

  def index
    # @users = User.all
  end

  def create
    super
  end

  def update
    super
  end

  private
    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

end
