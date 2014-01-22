class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :active_notebook
end
