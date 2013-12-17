class NotebookSerializer < ActiveModel::Serializer
  attributes :id, :guid, :title, :created_at, :updated_at, :user_id, :modview
end
