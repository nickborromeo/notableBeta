class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed
	validates_presence_of :guid, :rank, :depth

	def self.compileRoot
		# collect underpants
		compiledRoots = []
		roots = Note.where("parent_id ='root'").order(:rank)
		roots.each do |root|
			descendantList = Note.getCompleteDescendantList root
			if self.freshBranches?(descendantList) or root.fresh
				compiledRoots.push(:root => root,
													 :list => descendantList)
			end
		end
		everNoteData = []
		compiledRoots.each do |r|
			currentDepth = 1
			puts r[:root].title
			content = "<ul>"
			r[:list].each do |branch|
				content += '<ul>' if branch.depth > currentDepth and currentDepth+=1
				content += '</ul>' if branch.depth < currentDepth and currentDepth-=1
				content += " <li>#{branch.title}</li>"
			end
			currentDepth.downto(1).each do |level|
				content += "</ul>"
			end
			puts content
			everNoteData.push :title => r[:root].title, :content => content, :guid => r[:root].guid, :id => r[:root].id
		end
		# profit!!!
		# http://knowyourmeme.com/memes/profit
		everNoteData
	end
	# def self.formatListToEvernote (descendantList)
	# 	descendantList.

	# end
	def self.getCompleteDescendantList (root)
		descendantsList = []
		rec = -> (current) do
			descendantsList.push current if current.parent_id != 'root'
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
		Note.where("parent_id = '#{branch.guid}'").order(:rank)
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
