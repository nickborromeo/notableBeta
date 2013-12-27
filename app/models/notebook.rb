class Notebook < ActiveRecord::Base
  attr_accessible :modview, :title, :user_id, :guid
  has_many :notes, dependent: :destroy
  belongs_to :user

end
