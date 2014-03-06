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

	# notebooks => array received from backbone
	# [{0: {name: "[NAME]", eng: "[EVERNOTE_GUID]"}, {1: ...
	def self.createTrunks (notebooks, user)
		notebooks.each do |key, notebook|
			if Notebook.where("eng='#{notebook[:eng]}'").empty?
				fields = {
					title: notebook[:name],
					modview: "outline",
					user_id: user.id
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
