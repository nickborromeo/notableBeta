class NotebookSerializer < ActiveModel::Serializer
  attributes :guid, :title, :modview, :user_id
end
