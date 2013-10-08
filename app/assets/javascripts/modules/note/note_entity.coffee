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
			else @getDescendantCollection pid
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)
		insertInTree: (note, options) -> @add note, options # Alias

		removeNoteFromCollection: (collection, note) ->
			collection.remove note
			@decreaseRankOfFollowing note
	
		# returns the descendants of matching parent_id
		getCollection: (parent_id) ->
			if parent_id is 'root' then @
			else @getDescendantCollection parent_id
		getDescendantCollection: (pid) ->
			@findNote(pid).descendants
		findInCollection: (searchHash) ->
			@where searchHash
		findFirstInCollection: (searchHash) ->
			@findInCollection(searchHash)[0]

		# Search the whole tree recursively but top level
		# returns the element maching id
		# throws if fails  
		findNote: (guid) ->
			searchedNote = false
			searchRecursively = (currentNote, rest) ->
				return searchedNote unless !searchedNote and currentNote?
				if currentNote.get('guid') is guid
					return searchedNote = currentNote
				searchRecursively _.first(rest), _.rest rest
				if currentNote.descendants.length isnt 0 and not searchedNote
					searchRecursively currentNote.descendants.first(), currentNote.descendants.rest()
			searchRecursively @first(), @rest() # start search
			throw "#{guid} not found. Aborting" unless searchedNote
			searchedNote
		getNote: (guid) -> @findNote(guid) # alias

		# findInCollection: (guid) ->
		# 	elemSearched = false
		# 	@every (note) ->
		# 		if note.get('guid') is guid
		# 			noteSearched = note
		# 			false # break
		# 		else
		# 			true # continue
	
		getCompleteDescendantList: (parent_id) ->
			list = []
			descendants = @getCollection parent_id
			rec = (current, rest) =>
				return unless current?
				list.push current
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
				rec _.first(rest), _.rest rest
			rec descendants.first(), descendants.rest()
			list

		forEachInFilteredCollection: (parent_id, applyFunction, filterFunction = false) ->
			collection = @getCollection parent_id
			filteredNotes	= collection.filter filterFunction unless !filterFunction
			_.each filteredNotes, applyFunction, this


		cloneNote: (noteToBeCloned, noteToClone) ->
			attributesHash = {}
			toCloneAttributes = ['depth', 'rank', 'parent_id']
			attributesHash[attribute] = noteToClone.get(attribute) for attribute in toCloneAttributes
			noteToBeCloned.save attributesHash
		# Will generalize for more than one attribute
		modifyAttributes: (attribute, note, effect) ->
			attributeHash = {}
			attributeHash[attribute] = note.get(attribute) + effect
			note.save attributeHash

		modifyRank: (note, effect) -> @modifyAttributes 'rank', note, effect
		increaseRank: (note) -> @modifyRank note, 1
		decreaseRank: (note) -> @modifyRank note, -1
		filterFollowingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') <= comparingNote.get('rank') and self.get('guid') isnt comparingNote.get('guid')
		modifyRankOfFollowing: (self, applyingFunction) -> @forEachInFilteredCollection self.get('parent_id'), applyingFunction, @filterFollowingNotes(self)
		increaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, @increaseRank
		decreaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, @decreaseRank

		modifyDepth: (note, effect) -> @modifyAttributes 'depth', note, effect
		increaseDepth: (magnitude = 1) -> (note) => @modifyDepth note, magnitude
		decreaseDepth: (magnitude = 1) -> (note) => @modifyDepth note, -magnitude
		increaseDescendantsDepth: (pid, magnitude = 1) -> @modifyDescendantsDepth pid, @increaseDepth magnitude
		decreaseDescendantsDepth: (pid, magnitude = 1) -> @modifyDescendantsDepth pid, @decreaseDepth magnitude
		modifyDescendantsDepth: (pid, applyFunction) ->
			descendants = @getCompleteDescendantList pid
			_.each descendants, applyFunction

		findPreviousNoteInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') - 1
		findPreviousNote: (note) ->
			if note.get('rank') is 1
				return @getNote(note.get('parent_id'))
			previousNote = @findPreviousNoteInCollection note
			if previousNote.descendants.length is 0
				return previousNote
			@getCompleteDescendantList(previousNote.get('guid'))[-1..][0]
		findFollowingNoteInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') + 1
		findFollowingNote: (note) ->
			return note.descendants.models[0] unless note.descendants.length is 0
			followingNote = undefined
			findFollowingRecursively = (note) =>
				if !(followingNote = @findFollowingNoteInCollection note)? and
					 note.get('parent_id') is 'root'
					return undefined
				return followingNote unless !followingNote?
				findFollowingRecursively @getNote note.get 'parent_id'
			findFollowingRecursively note
			followingNote
		jumpNoteUpInCollection: (note) ->
			return undefined unless note.get('rank') > 1
			previousNote = @findPreviousNoteInCollection note
			@decreaseRank note
			@increaseRank previousNote
			@getCollection(note.get 'parent_id').sort()
		jumpNoteDownInCollection: (note) ->
			followingNote = @findFollowingNoteInCollection note
			return undefined unless followingNote?
			@decreaseRank followingNote
			@increaseRank note
			@getCollection(note.get 'parent_id').sort()
		jumpNoteUp: (note) ->
			previousNote = @findPreviousNote note
			if previousNote.get('parent_id') is note.get 'parent_id'
				@jumpNoteUpInCollection note
			else if (depthDifference = previousNote.get('depth') - note.get('depth')) > 0
				@tabNote note for i in [depthDifference..1]
			else
				undefined
				previousCollection = @getCollection note.get 'parent_id'
				@removeNoteFromCollection previousCollection, note
				@cloneNote note, previousNote
				@insertInTree note
				@increaseRankOfFollowing note
				newCollection = @getCollection note.get('parent_id')
				@decreaseDescendantsDepth note.get('guid'), Math.abs depthDifference
				newCollection.sort()
				note
		# jumpNoteUp: (note) ->
		# 	@jumpNoteUpInCollection note
		jumpNoteDown: (note) ->
			@jumpNoteDownInCollection note
		jumpFocusToFollowingNote: (note) ->
			return followingNote if (followingNote = @findFollowingNote note)?
		jumpFocusToPreviousNote: (note) ->
			return previousNote if (previousNote = @findPreviousNote note)?	

		# increaseDescendantsDepth: (pid) ->
		# 	@modifyDescendantsDepth pid, 1
		# decreaseDescendantsDepth: (pid) ->
		# 	@modifyDescendantsDepth pid, -1
		# modifyDescendantsDepth: (pid, addTo) ->
		# 	descendants = @getCompleteDescendantList pid
		# 	_.each descendants, (note) ->
		# 		note.save
		# 			depth: note.get('depth') + addTo

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

		createNote: (precedentNote, text) ->
			@increaseRankOfFollowing precedentNote
			@create @generateAttributes(precedentNote, text)
		generateAttributes: (precedentNote, text) ->
			title: text
			rank: 1 + precedentNote.get 'rank'
			parent_id: precedentNote.get 'parent_id'
			depth: precedentNote.get 'depth'
		deleteNote: (note) ->
			pid = note.get 'parent_id'
			rank = note.get 'rank' 
			descendants = @getCompleteDescendantList note.get 'guid'
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
				parent_id: parent.get 'guid'
				rank: parent.descendants.length + 1
				depth: 1 + note.get 'depth'
			@insertInTree note
			previousParentCollection.remove note
			@increaseDescendantsDepth note.get 'guid'
		findNewParent: (parentCollection, rank) ->
			parentCollection.findFirstInCollection rank: rank - 1
		unTabNote: (note) ->
			return false unless note.get('depth') > 0
			previousParent = @getNote note.get 'parent_id'
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
			@decreaseDescendantsDepth note.get 'guid'

		comparator: (note) ->
			note.get 'rank'

)
