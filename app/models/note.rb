class Note < ActiveRecord::Base
  attr_accessible :subtitle, :title, :guid, :parent_id, :rank, :depth
end
