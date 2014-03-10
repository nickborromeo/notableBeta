class Notebook < ActiveRecord::Base
  attr_accessible :guid, :title, :modview, :user_id, :eng, :trashed
  has_many :notes, dependent: :destroy
  belongs_to :user

	def self.getTrashed
		Notebook.where("trashed = true")
	end

	def self.deleteByEng (eng)
		notebook = Notebook.find_by_eng(eng)
		notebook.destroy if notebook
	end

	# notebooks => array received from evernote through user selection
	# [{0: {name: "[NAME]", eng: "[EVERNOTE_GUID]"}, {1: {name:
  # "[NAME OF SECOND NOTEBOOK]", eng: "[GUID OF SECOND NOTEBOOK]"} ...
	def self.createTrunks (notebooks, user)
		notebooks.each do |key, notebook|
			if Notebook.where("eng='#{notebook[:eng]}'").empty?
				fields = {
					title: notebook[:name],
					modview: "outline",
					user_id: user.id,
					guid: notebook[:eng],
					eng: notebook[:eng],
					trashed: false
				}
				trunk = Notebook.new fields
				trunk.save
			else
				puts "Error: Notebook already exists"
			end

		end
	end


end
