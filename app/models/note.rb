class Note < ActiveRecord::Base
  attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed

  validates_presence_of :guid, :rank, :depth
end
