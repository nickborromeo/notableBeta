class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  before_filter :admin_user,     only: [:destroy, :index]

  def index
    @users = User.order("email")
  end

  def create
    super
    makeDefaultNotebook
  end

  def update
    super
  end

  private
    def makeDefaultNotebook
      tutorial = { "guid" => SecureRandom.uuid,
        "title" => "Notable Tutorial",
        "modview" => "outline",
        "user_id" => current_user.id
      }
      @default_notebook = Notebook.new(tutorial)
      @default_notebook.save
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
