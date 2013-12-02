class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed
	validates_presence_of :guid, :rank, :depth

	private
		def compileRoot (guid)
			# collect underpants
			# some kind of loop function ?
			# profit!!!
			# http://knowyourmeme.com/memes/profit
		end

end
