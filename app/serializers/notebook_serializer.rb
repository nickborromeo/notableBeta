class NotebookSerializer < ActiveModel::Serializer
  attributes :id, :guid, :title, :modview, :user_id
end
