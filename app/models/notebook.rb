class Notebook < ActiveRecord::Base
  attr_accessible :guid, :title, :modview, :user_id, :eng, :trashed
  has_many :notes, dependent: :destroy
  belongs_to :user

	def self.getTrashed
		Notebook.where("trashed = true")
	end

	def self.deleteByEng (eng)
		notebook = Notebook.where("eng = '#{eng}'").first
		return if notebook.nil?
		notebook.destroy
	end

end
