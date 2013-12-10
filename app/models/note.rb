class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed
	validates_presence_of :guid, :rank, :depth

	def self.compileRoot
		compiledRoots = []
		roots = Note.where("parent_id ='root'").order(:rank)
		roots.each do |root|
			descendantList = Note.getCompleteDescendantList root
			if self.freshBranches?(descendantList) or root.fresh
				compiledRoots.push(:root => root.title,
													 :list => descendantList)
			end
		end
		compiledRoots.each do |r|
			puts "<ul><li>#{r[:root]}</li>"
			r[:list].each do |branch|
				puts "  <li>#{branch.title}</li>"
			end
			puts "</ul>"
		end
		# collect underpants
		# some kind of loop function ?
		# profit!!!
		# http://knowyourmeme.com/memes/profit
	end
	# def self.formatListToEvernote (descendantList)
	# 	descendantList.

	# end
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

	def self.freshBranches? (descendantList)
		fresh = false
		descendantList.each do |descendant|
			fresh = descendant.fresh
			break if fresh == true
		end
		fresh
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
