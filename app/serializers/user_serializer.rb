class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :admin, :active_notebook
end
