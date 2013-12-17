class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessible :email, :password, :password_confirmation,
  	:remember_me, :token_credentials, :last_full_sync, :last_update_count
	has_many :notebooks, dependent: :destroy

end
