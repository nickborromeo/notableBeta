class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed
	validates_presence_of :guid, :rank, :depth

	def self.compileRoot
		compiledRoots = []
		roots = Note.where("parent_id ='root'")
		roots.each do |root|
			compiledRoots.push Note.getCompleteDescendantList root
		end
		compiledRoots.each do |r|
			puts "ROOT --"
			r.each do |branch|
				puts branch.title
			end
		end
		# collect underpants
		# some kind of loop function ?
		# profit!!!
		# http://knowyourmeme.com/memes/profit
	end
	
	def self.getCompleteDescendantList (root)
		descendantsList = []
		rec = -> (current) do
			descendantsList.push current
			descendants = Note.getDescendants current
			descendants.each do |d|
				rec.call d
			end
		end
		rec.call root
		descendantsList
	end

	def self.rootIsFresh (descendantList)
		descendantList.each do |descendant|

		end
	end
	
	def self.getDescendants (branch)
		Note.where "parent_id = '#{branch.guid}'"
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
