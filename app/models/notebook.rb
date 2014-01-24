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
		self.deleteRelatedNotes notebook
		notebook.destroy
	end
	def self.deleteRelatedNotes (notebook)
		branchesToDelete = Note.where("parent_id='root' AND notebook_id=#{notebook.id}")
		branchesToDelete.each do |b|
			Note.deleteBranch b
		end
	end

end
