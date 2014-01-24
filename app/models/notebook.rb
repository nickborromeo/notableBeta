class Notebook < ActiveRecord::Base
  attr_accessible :guid, :title, :modview, :user_id, :eng, :trashed
  has_many :notes, dependent: :destroy
  belongs_to :user

end
