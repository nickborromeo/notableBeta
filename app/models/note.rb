class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed
	validates_presence_of :guid, :rank, :depth

	def compileRoot (branches)
		# collect underpants
		# some kind of loop function ?
		# profit!!!
		# http://knowyourmeme.com/memes/profit
	end

	def compileBranches (root)
		data #breakdown into branches
		# with an appropriate rank, depth
		# title, subtitle, parent_id
		collapsed = false
		fresh = false
		guid = @noteGuid
	end

	def markStale
		if branch.isCompiled?
			branch.fresh = false
		end
	end

end
