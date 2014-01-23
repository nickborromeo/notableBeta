class Note < ActiveRecord::Base
	require 'securerandom'
	attr_accessible :guid, :eng, :title, :subtitle, :parent_id, :rank, :depth, :collapsed, :fresh, :trashed, :notebook_id
	validates_presence_of :guid, :rank, :depth
  belongs_to :notebook

  include PgSearch
  pg_search_scope :pg_search, against: [:title, :subtitle],
  	using: {tsearch: { dictionary: "english" }},
  	associated_against: {notebook: :title} #,
  	# ignoring: :accents

  def self.search(query)
  	if query.present?
  		pg_search(query)
  	else
  		scoped.order('created_at DESC')
  	end
  end

	def self.compileRoot (notebook_id)
		compiledRoots = []
		notebook = Notebook.where("id = #{notebook_id}").first
		roots = Note.where("parent_id ='root' AND notebook_id=#{notebook_id}").order(:rank)
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
				content += '</li>' if branch.depth == currentDepth and not content.index('<li>').nil?
				content += '<ul>' if branch.depth > currentDepth and currentDepth+=1
				if branch.depth < currentDepth
					content += '</li>'
					currentDepth.downto(branch.depth+1).each do |level|
						content += '</ul></li>'
					end
					currentDepth = branch.depth
				end
				content += "<li>#{branch.title}"
			end
			content += "</li>" if not content.index('<li>').nil?
			currentDepth.downto(2).each do |level|
				content += "</ul></li>"
			end
			content += "</ul>"
			puts "SENT CONTENT"
			puts content
			evernoteData.push(:title => r[:root].title,
												:content => content,
												:guid => r[:root].eng,
												:id => r[:root].id,
												:created_at => r[:root].created_at,
												:notebookid => notebook.id,
												:notebookEng => notebook.eng,
												:eng => r[:root].eng)
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
		self.decreaseRankOfFollowing branch.rank
		self.deleteDescendants branch
		Note.find(branch[:id]).destroy
	end

	def self.deleteDescendants (branch)
		descendantList = Note.getCompleteDescendantList branch
		descendantList.each do |b|
			Note.find(b[:id]).destroy
		end
	end

	def self.decreaseRankOfFollowing (rank)
		notes = Note.where("depth = 0")
		notes.each do |n|
			if n.rank > rank
				Note.update(n.id, :rank => n.rank - 1)
			end
		end
	end

	def self.receiveBranches (branchData)
		rank = self.getLastRank
		branchData.each do |data|
			branch = Note.where("eng = '#{data[:eng]}'").first
			if branch.nil?
				rank += 1
				self.createBranch data, rank
			else
				self.updateBranch data
			end
		end
	end

	def self.updateBranch (data)
		branch = Note.where("eng = '#{data[:eng]}'").first
		data[:content] = self.digestEvernoteContent branch.guid, data[:content]
		self.deleteDescendants branch
		Note.update(branch.id, :title => data[:title])
		self.createDescendants data
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

		branch = Note.new(branch)
		branch.save
		data[:content] = self.digestEvernoteContent branch.guid, data[:content]
		self.createDescendants data
		branch
	end

	def self.createDescendants (data)
		descendants = data[:content]
		descendants.each do |d|
			descendant = Note.new d
			descendant.save
		end
	end

	def self.digestEvernoteContent (parent_id, content)
		self.parseContent parent_id, content
	end

	# this obscur code retrieve what is between <en-note>...</en-note> and trims the rest		
	def self.retrieveContentFromEnml (content)
		if not content.index(/<en-note( .*?)?>/).nil? 
			content = content.slice((i1 = content.index($~[0]) + $~[0].size), (content.index('</en-note>') - i1))
		end
		content
	end

	def self.dispatchParsing
	end

	def self.trimContent (content)
		content = self.retrieveContentFromEnml content
		content = self.transformPlainText content # if content.index('<ul>').nil?
		content = content.gsub />(\s)+</, '><' # Delete space between <tags>
		content = content.gsub /<(\/)?(?!ul|li|ol|\/ul|\/ol)(.*?)?(\/)?>/, ''  # strip out any other not li or ul tags
		# content = content.gsub /<(\/)?(?!ul|li|ol)(.*?)?(\/)?>/, '' # strip out any other not li or ul tags
		content = content.gsub /<li (.*?)style=('|").*?none.*?('|")(.*?)>/, '' # To strip out hidden li added by mce editor in evernote
		content = content.gsub /<ol( .*?)?>/, '<ul>' # Strip <li|ul style="".. or w/e could be in the tag as well
		content = content.gsub /<li( .*?)?>/, '<li>' # Strip <li|ul style="".. or w/e could be in the tag as well
		content = content.gsub /<ul( .*?)?>/, '<ul>'
		content = content.gsub /<\/li>/, '' # Strip out closing li
		if content.match /<ul>(<ul>)+/
			content = content.gsub /<(\/)?ul>/, '' # stip out all uls
			content = '<ul>' + content + '</ul>'
		end
		puts "CONTENT"
		puts content
		content
	end

	def self.getContentNextLi (content)
		t = content.slice '<li>'.size, content.index(/<(\/)?(li|ul)>/, 4) - '<li>'.size
		{:title  => t, :index => $~.begin(0)}
	end

	# def self.getContentNextLi (content)
	# 	nextTag = content.index(/<(\/)?(li|ul)>/, 4)
	# 	nextTag ||= content.size # Meaning there is only a li tag left open, and no closing tag
	# 	t = content.slice '<li>'.size, nextTag - '<li>'.size
	# 	if not $~.nil?
	# 		index = $~.begin(0)
	# 	else
	# 		index = content.size
	# 	end
		
	# 	{:title  => t, :index => index}
	# end

	def self.transformPlainText (content)
		content = content.gsub '<div></div>', ''
		content = content.gsub '<div>', '<li>'
		content = content.gsub '<p>', '<li>'
		content = '<ul>' + content + '</ul>' if content.index('<ul>').nil? or not content.index('<ul>').zero?
		content
	end

	def self.parseContent (parent_id, content)
		content = self.trimContent content
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
				hash = self.getContentNextLi content
				title = hash[:title]
				index = hash[:index]
				notes.push :depth => indentation, :title => title, :guid => SecureRandom.uuid
				rec.call(content.slice index, content.size)
			else
				notes
			end
		end
		rec.call content

		preceding = {:depth => 0, :title => "who cares!", :guid => parent_id}
		parents = [{:guid => parent_id, :next_rank => 1}]
		notes2 = notes
		notes2.each do |n|
			parent = parents[n[:depth] - 1]
			if n[:depth] > preceding[:depth]
				parents[preceding[:depth]] = {:guid => preceding[:guid], :next_rank => 2}
				n[:rank] = 1
				n[:parent_id] = preceding[:guid]
			elsif n[:depth] < preceding[:depth]
				n[:rank] = parent[:next_rank]
				n[:parent_id] = parent[:guid]
				parent[:next_rank] += 1
			else
				n[:rank] = parent[:next_rank]
				n[:parent_id] = parent[:guid]
				parent[:next_rank] += 1
			end
			preceding = n
		end

		notes
	end

	def self.getLastRank
		lastNote = Note.order("depth, rank DESC").first
		if lastNote.nil?
			0
		else
			lastNote.rank
		end
	end

	def self.setDefaultAttributes (data)
		defaults = {
			:collapsed => false,
			:fresh => false,
			:guid => data[:eng],
		}
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

	def self.getTrashed
		Note.where("trashed = true AND parent_id = 'root'")
	end

end
