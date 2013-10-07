@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
 
	class Note.Model extends Backbone.Model
		urlRoot : '/notes'
		defaults:
			title: "Just type here to create a note"
			subtitle: ""
			parent_id: "root"
			rank: 1
			depth: 0

		initialize: ->
			@descendants = new App.Note.Tree()
			if @isNew()
				@set 'created', Date.now()
				@set 'guid', @generateGuid()
		generateGuid: ->
			guidFormat = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
			guid = guidFormat.replace(/[xy]/g, (c) ->
				r = Math.random() * 16 | 0
				v = (if c is "x" then r else (r & 0x3 | 0x8))
				v.toString 16
			)
			guid

	# class Note.child extends Note.Model	
	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get 'depth'

	class Note.Tree extends Backbone.Collection
		url:'/notes'
		model: Note.Model

		initialize: ->

		# Manage note insertion in the nested structuer	
		add: (note, options) ->		
			pid = note.get 'parent_id'
			collectionToAddTo =
			if pid is 'root' or pid is undefined then @
			else @findDescendants pid
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)
		insertInTree: (note, options) -> @add note, options # Alias

		# returns the descendants of matching parent_id
		getCollection: (parent_id) ->
			if parent_id is 'root' then @
			else @findDescendants parent_id
		findDescendants: (pid) ->
			@search(pid).descendants
		findInCollection: (searchHash) ->
			@where searchHash
		findFirstInCollection: (searchHash) ->
			@findInCollection(searchHash)[0]

		# Search the whole tree recursively but top level
		# returns the element maching id
		# throws if fails  
		search: (pid) ->
			deepSearch = (id) =>
				desc_found = false
				searchRec = (elem, rest) ->
					return desc_found unless !desc_found and elem?
					if elem.get('id') is parseFloat id
						return desc_found = elem
					searchRec _.first(rest), _.rest rest
					if elem.descendants.length isnt 0 and not desc_found
						searchRec elem.descendants.first(), elem.descendants.rest()
				searchRec @first(), @rest() # start search
				throw "#{id} not found. Aborting" unless desc_found
				desc_found
			(@get(pid) || deepSearch pid) # Check in top level first, else launch deepSearch

		getCompleteDescendantList: (parent_id) ->
			list = []
			descendants = @getCollection parent_id
			rec = (current, rest) =>
				return unless current?
				list.push current
				rec _.first(rest), _.rest rest
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
			rec descendants.first(), descendants.rest()
			list

		eachFilterCollection: (parent_id, mapFunction, filterFunction = false) ->
			collection = @getCollection parent_id
			filteredNotes	= collection.filter filterFunction unless !filterFunction
			_.each filteredNotes, mapFunction, this
		# Will generalize for more than one attribute
		modifyAttributes: (attribute, note, effect) ->
			attributeHash = {}
			attributeHash[attribute] = note.get(attribute) + effect
			note.save attributeHash

		modifyRank: (note, effect) -> @modifyAttributes 'rank', note, effect
		increaseRank: (note) -> @modifyRank note, 1
		decreaseRank: (note) -> @modifyRank note, -1
		filterFollowingNotes: (self) -> (comparingNote) ->
			self.get('rank') <= comparingNote.get('rank') and self.get('guid') isnt comparingNote.get('guid')
		modifyRankOfFollowing: (self, applyingFunction) ->
			@eachFilterCollection self.get('parent_id'), applyingFunction, @filterFollowingNotes(self)
		increaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, @increaseRank
		decreaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, @decreaseRank
		
		# increaseRankoffFollowing (self, parent_id, rank)
		# increaseRankofFollowing: (parent_id, rank) ->
		# 	@modifyRankOfFollowing parent_id, rank, 1
		# decreaseRankOfFollowing: (parent_id, rank) ->
		# 	@modifyRankOfFollowing parent_id, rank, -1
		# modifyRankOfFollowing: (parent_id, rank, toAdd) ->
		# 	previousColl = @getCollection parent_id
		# 	previousColl.modifyRankInCollection rank, toAdd
		# modifyRankInCollection: (rank, toAdd) ->
		# 	notesToDecrease = @filter (note) -> rank < note.get('rank')
		# 	_.each notesToDecrease, (note) ->
		# 		note.save
		# 			rank: note.get('rank') + toAdd

		increaseDescendantsDepth: (pid) ->
			@modifyDescendantsDepth pid, 1
		decreaseDescendantsDepth: (pid) ->
			@modifyDescendantsDepth pid, -1
		modifyDescendantsDepth: (pid, addTo) ->
			descendants = @getCompleteDescendantList pid
			_.each descendants, (note) ->
				note.save
					depth: note.get('depth') + addTo

		createNote: (precedentNote, text) ->
			@increaseRankOfFollowing precedentNote
			@create @generateAttributes(precedentNote, text), wait: true
		generateAttributes: (precedentNote, text) ->
			title: text
			rank: 1 + precedentNote.get 'rank'
			parent_id: precedentNote.get 'parent_id'
			depth: precedentNote.get 'depth'
		deleteNote: (note) ->
			pid = note.get 'parent_id'
			rank = note.get 'rank' 
			descendants = @getCompleteDescendantList note.get 'id'
			_.each descendants, (descendant) ->
				descendant.destroy()
			self = note
			note.destroy success: @decreaseRankOfFollowing self

		tabNote: (note) ->
			return false unless note.get('rank') > 1
			previousRank = note.get 'rank'
			previousPid = note.get 'parent_id'
			previousParentCollection = @getCollection previousPid
			parent = @findNewParent previousParentCollection, previousRank
			@decreaseRankOfFollowing note
			note.save
				parent_id: parent.get 'id'
				rank: parent.descendants.length + 1
				depth: 1 + note.get 'depth'
			@insertInTree note
			previousParentCollection.remove note
			@increaseDescendantsDepth note.get 'id'
		findNewParent: (parentCollection, rank) ->
			parentCollection.findFirstInCollection rank: rank - 1
		unTabNote: (note) ->
			return false unless note.get('depth') > 0
			previousParent = @search note.get 'parent_id'
			newParentCollection = @getCollection previousParent.get 'parent_id'
			newParentId = previousParent.get('parent_id')
			previousRank = note.get 'rank'
			previousParent.descendants.remove note
			newRank = previousParent.get('rank') + 1
			@increaseRankOfFollowing previousParent
			@decreaseRankOfFollowing note
			note.save
				parent_id: newParentId
				rank: newRank
				depth: note.get('depth') - 1
			@insertInTree note
			@decreaseDescendantsDepth note.get 'id'
		getNote: (id) ->
			@search(id)

		comparator: (note) ->
			note.get 'rank'

)
