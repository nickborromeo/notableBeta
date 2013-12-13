class Note < ActiveRecord::Base
	attr_accessible :guid, :title, :subtitle, :parent_id, :rank, :depth, :collapsed, :fresh
	validates_presence_of :guid, :rank, :depth
  belongs_to :notebook

	def self.compileRoot
		compiledRoots = []
		roots = Note.where("parent_id ='root'").order(:rank)
		roots.each do |root|
			descendantList = Note.getCompleteDescendantList root
			if self.freshBranches?(descendantList) or root.fresh
				compiledRoots.push(:root => root,
													 :list => descendantList)
			end
		end
		evernoteData = []
		compiledRoots.each do |r|
			currentDepth = 1
			content = "<ul>"
			r[:list].each do |branch|
				content += '<ul>' if branch.depth > currentDepth and currentDepth+=1
				content += '</ul>' if branch.depth < currentDepth and currentDepth-=1
				content += " <li>#{branch.title}</li>"
			end
			currentDepth.downto(1).each do |level|
				content += "</ul>"
			end
			notebookGuid = Notebook.where("id = #{r[:root].notebook_id}").first.guid
			evernoteData.push(:title => r[:root].title,
												:content => content,
												:guid => r[:root].eng,
												:id => r[:root].id,
												:created_at => r[:root].created_at,
												:notebookGuid => notebookGuid)
		end
		evernoteData
	end

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

	def self.getDescendants (branch)
		Note.where("parent_id = '#{branch.guid}'").order(:rank)
	end

	def self.deleteByEng (eng)
		Note.deleteBranch Note.where("eng = '#{eng}'").first
	end

	def self.deleteBranch (branch)
		puts "?"
		return false if branch.nil?
		descendantList = Note.getCompleteDescendantList branch
		descendantList.each do |b|
			puts "destroy #{b[:title]}"
			Note.find(b[:id]).destroy
		end
		Note.find(branch[:id]).destroy
		puts "destroy root #{branch[:title]}"
	end

	def self.freshBranches? (descendantList)
		fresh = false
		descendantList.each do |descendant|
			fresh = descendant.fresh
			break if fresh == true
		end
		fresh
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
