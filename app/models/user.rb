class User < ActiveRecord::Base
  attr_accessible :admin, :email, :username
end
