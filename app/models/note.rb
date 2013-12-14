class Note < ActiveRecord::Base
	require 'securerandom'
	attr_accessible :guid, :eng, :title, :subtitle, :parent_id, :rank, :depth, :collapsed, :fresh
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
			# notebookGuid = Notebook.where("id = #{r[:root].notebook_id}").first.guid
			notebookGuid = nil
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
		return false if branch.nil?
		descendantList = Note.getCompleteDescendantList branch
		descendantList.each do |b|
			puts "destroy #{b[:title]}"
			# Note.find(b[:id]).destroy
		end
		# Note.find(branch[:id]).destroy
		puts "destroy root #{branch[:title]}"
	end

	def self.receiveBranches (branchData)
		rank = self.getLastRank
		branchData.each do |data|
			branch = Note.where("eng = '#{data[:eng]}'").first
			data[:content] = self.digestEvernoteContent data[:content]
			if branch.nil?
				rank += 1
				self.createBranch data, rank 
			else
				self.updateBranch data
			end		
		end
	end

	def self.createBranch (data, rank)
		puts "ARe you coming her?"
		branch = {
			:parent_id => 'root',
			:title => data[:title],
			:guid => data[:eng],
			:eng => data[:eng],
			:rank => rank,
			:depth => 0,
			:fresh => false,
			:collapsed => false
		}
		puts branch
		
		branch = Note.new(branch)
		branch.save
		self.parseContent(branch.guid, data[:content])
		# descendant[:parent_id] = 'root'
		# descendant[:title] = data[:content]
		# descendant[:guid] = #{SecureRandom.uuid}
		# descendant[:eng] = nil
		# descendant[:rank] = self.getLastRank
		# descendant[:depth] = 0
		# descendant[:fresh] = false
		# descendant[:collapsed] = false
		branch
	end

	# this obscur code retrieve what is between <en-note>...</en-note> and trims the rest
	def self.trimContent (content)
		content = content.slice((i1 = content.index('<en-note>') + '<en-note>'.size), (content.index('</en-note>') - i1))
		content.gsub />(\s)+</, '><' # Delete space between <tags>
	end

	def self.processNextTag (content)
			
	end

	def self.getContentNextLi (content)
		content.slice '<li>'.size, content.index('</li>') - '<li>'.size
	end

	def self.parseContent (parent_id, content)
		puts content = self.trimContent content
		notes = []
		indentation = 0
		rec = -> (content) do
			if not (test = content.index('<ul>')).nil? and test.zero?
				indentation +=1
				rec.call content.slice content.index('<li>'), content.size
			elsif not (test = content.index('</ul>')).nil? and test.zero?
				indentation -=1
				rec.call content.slice '</ul>'.size, content.size
			elsif not (test = content.index('<li>')).nil? and test.zero?
				title = self.getContentNextLi content
				notes.push :depth => indentation, :title => title, :guid => SecureRandom.uuid
				rec.call(content.slice content.index('</li>') + '</li>'.size, content.size)
			else
				notes
			end
		end
		rec.call content

		# makeNote = -> (current, rest, preceding) do
		# 	return if current.nil?

		# end
		# depth = 0
		# currentObject = ""
		# nextMatch = "<"
		# content.each do |c|
		# 	if c != nextMatch
		# 		currentObject += c
		# 	elsif nextMatch = '<'
						 
		# 	end
		# 	if nextMatch == c
				
		# 	end
		# 	# if c == '<'
		# 	# 	currentObject = c
		# 	# 	nextMatch = '>'
		# 	# end
			
		# end
		# rec = -> (content) do
		# 	# return if (currentUl = content.index('<ul>')).nil?
		# 	currentUl = content.index('<ul>')
		# 	if currentUl.zero?
		# 		depth+=1
		# 		nextUl = content.index('<ul>',4)
		# 		while (nextLi = content.index('<li>') + '<li>'.size) < nextUl
		# 			closingLi = content.index '</li>'
		# 			sliceLength = closingLi - nextLi
		# 			content.slice nextLi, sliceLength
		# 		end
		# 	end
			
		# 	nextClosing = content.index('</ul>')
		# 	if nextClosing > currentUl
				
		# 	end
		# end
		# descendant = {
		# 	:parent_id => data[:eng],
		# 	:title => data[:content],
		# 	:guid => SecureRandom.uuid,
		# 	:eng => nil,
		# 	:rank => 1,
		# 	:depth => 1,
		# 	:fresh => false,
		# 	:collapsed => false
		# }
		# puts descendant
		# descendant = Note.new(descendant)
		# descendant.save

	end

	def self.getLastRank
		lastNote = Note.order("depth, rank DESC").first
		if lastNote.nil?
			0
		else
			lastNote.rank
		end
	end

	def self.updateBranch (data)
	end

	def self.setDefaultAttributes (data)
		defaults = {
			:collapsed => false,
			:fresh => false,
			:guid => data[:eng],
		}
	end

	def self.digestEvernoteContent (content)
		content
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
