class NoteSerializer < ActiveModel::Serializer
  attributes :id, :title, :subtitle, :created_at
end
