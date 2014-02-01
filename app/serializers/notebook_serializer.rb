class NotebookSerializer < ActiveModel::Serializer
  attributes :id, :guid, :eng, :title, :modview, :user_id
end
