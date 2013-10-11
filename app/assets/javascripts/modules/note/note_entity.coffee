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
			@descendants = new App.Note.Trunk()
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

		isARoot: ->
			@get('parent_id') is 'root'
		isInSameCollection: (note) ->
			@get('parent_id') is note.get('parent_id')

		getCompleteDescendantList: ->
			buildList = (descendantsBranch, descendantList) ->
				descendantsBranch.inject (descendantsBranch, descendant) ->
					descendantList.concat descendant, buildList(descendant.descendants, [])
				, []
			buildList @descendants, []
		firstDescendant: ->
			@descendants.models[0]
		getLastDescendant: ->
			@getCompleteDescendantList()[-1..][0]

		clonableAttributes: ['depth', 'rank', 'parent_id']
		cloneAttributes: (noteToClone) ->
			attributesHash = {}
			attributesHash[attribute] = noteToClone.get(attribute) for attribute in @clonableAttributes
			@save attributesHash

		# Will generalize for more than one attribute
		modifyAttributes: (attribute, effect) ->
			attributeHash = {}
			attributeHash[attribute] = @get(attribute) + effect
			@save attributeHash

		modifyRank: (effect) -> @modifyAttributes 'rank', effect
		increaseRank: () -> @modifyRank 1
		decreaseRank: () -> @modifyRank -1

		modifyDepth: (effect) -> @modifyAttributes 'depth', effect
		increaseDepth: (magnitude = 1) -> @modifyDepth magnitude
		decreaseDepth: (magnitude = 1) -> @modifyDepth -magnitude
		increaseDescendantsDepth: (magnitude = 1) ->
			@modifyDescendantsDepth increaseDepthOfNote magnitude
		decreaseDescendantsDepth: (magnitude = 1) ->
			@modifyDescendantsDepth decreaseDepthOfNote magnitude
		modifyDescendantsDepth: (modifierFunction) ->
			descendants = @getCompleteDescendantList()
			_.each descendants, modifierFunction

	# Static Function
	Note.Model.generateAttributes = (precedingNote, text) ->
		title: text
		rank: 1 + precedingNote.get 'rank'
		parent_id: precedingNote.get 'parent_id'
		depth: precedingNote.get 'depth'

	# Helper Functions (to be moved)
	# For use as a higher order function
	increaseRankOfNote = (note) -> note.increaseRank()
	decreaseRankOfNote = (note) -> note.decreaseRank()
	increaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.increaseDepth(magnitude)
	decreaseDepthOfNote = (magnitude = 1) ->
		(note) -> note.decreaseDepth(magnitude)

	# class Note.child extends Note.Model
	class Note.Collection extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		comparator: (note) ->
			note.get 'depth'

	class Note.Trunk extends Backbone.Collection
		model: Note.Model
		url:'/notes'

		# Manage note insertion in the nested structure
		add: (note, options) ->
			pid = note.get 'parent_id'
			collectionToAddTo =
			if pid is 'root' or pid is undefined then @
			else @getDescendantCollection pid
			Backbone.Collection.prototype.add.call(collectionToAddTo, note, options)
		insertInTree: (note, options) ->
			@add note, options
			newCollection = @getCollection note.get 'parent_id'
			if note.get('rank') < newCollection.length
				@increaseRankOfFollowing note
			if note.descendants.length isnt 0
				firstDescendantDepth = note.firstDescendant().get('depth')
				depthDifference = note.get('depth') - firstDescendantDepth + 1
				if depthDifference isnt 0
					note.increaseDescendantsDepth depthDifference
			newCollection.sort()
		removeFromCollection: (collection, note) ->
			collection.remove note
			@decreaseRankOfFollowing note

		createNote: (precedingNote, text) ->
			@increaseRankOfFollowing precedingNote
			@create Note.Model.generateAttributes(precedingNote, text)
		deleteNote: (note) ->
			descendants = note.getCompleteDescendantList()
			_.each descendants, (descendant) ->
				descendant.destroy()
			note.destroy success: (self) => @decreaseRankOfFollowing self

		# Returns the descendants of matching parent_id
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
		# Returns the element maching id and throws error if this fails
		findNote: (guid) ->
			searchedNote = false
			searchRecursively = (currentNote, rest) ->
				return searchedNote if searchedNote or !currentNote?
				if currentNote.get('guid') is guid
					return searchedNote = currentNote
				searchRecursively _.first(rest), _.rest rest
				if currentNote.descendants.length isnt 0 and not searchedNote
					searchRecursively currentNote.descendants.first(), currentNote.descendants.rest()
			searchRecursively @first(), @rest() # start search
			throw "#{guid} not found. Aborting" unless searchedNote
			searchedNote
		getNote: (guid) -> @findNote(guid) # alias
		findByGuidInCollection: (guid) ->
			noteSearched = false
			@every (note) ->
				if note.get('guid') is guid
					noteSearched = note
					false # break
				else
					true # continue
			noteSearched

		modifySiblings: (parent_id, modifierFunction, filterFunction = false) ->
			siblingNotes = @getCollection parent_id
			if filterFunction
				siblingNotes	= siblingNotes.filter filterFunction
			_.each siblingNotes, modifierFunction, this

		filterPrecedingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') >= comparingNote.get('rank') and
				self.get('guid') isnt comparingNote.get('guid')
		filterFollowingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') <= comparingNote.get('rank') and
				self.get('guid') isnt comparingNote.get('guid')
		modifyRankOfFollowing: (self, modifierFunction) ->
			findFollowing = @filterFollowingNotes(self)
			@modifySiblings self.get('parent_id'), modifierFunction, findFollowing
		increaseRankOfFollowing: (self) ->
			@modifyRankOfFollowing self, increaseRankOfNote
		decreaseRankOfFollowing: (self) ->
			@modifyRankOfFollowing self, decreaseRankOfNote

		findPrecedingInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') - 1
		findPreviousNote: (note) ->
			return undefined if (note.isARoot() and note.get('rank') is 1)
			if note.get('rank') is 1
				return @getNote(note.get('parent_id'))
			previousNote = @findPrecedingInCollection note
			if previousNote.descendants.length is 0
				return previousNote
			previousNote.getLastDescendant()
		findFollowingNoteInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') + 1
		findFollowingNote: (note, checkDescendants = true) ->
			return note.firstDescendant() if checkDescendants and note.descendants.length isnt 0
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
			previousNote = @findPrecedingInCollection note
			note.decreaseRank()
			previousNote.increaseRank()
			@getCollection(note.get 'parent_id').sort()
		jumpNoteDownInCollection: (note) ->
			followingNote = @findFollowingNoteInCollection note
			return undefined unless followingNote?
			followingNote.decreaseRank()
			note.increaseRank()
			@getCollection(note.get 'parent_id').sort()
		jumpPositionUp: (note) ->
			previousNote = @findPreviousNote note
			if note.isInSameCollection previousNote
				@jumpNoteUpInCollection note
			else if (depthDifference = previousNote.get('depth') - note.get('depth')) > 0
				@tabNote note for i in [depthDifference..1]
			else
				previousCollection = @getCollection note.get 'parent_id'
				@removeFromCollection previousCollection, note
				note.cloneAttributes previousNote
				@insertInTree note
				note
		jumpPositionDown: (note) ->
			followingNote = @findFollowingNote note, false
			if note.isInSameCollection followingNote
				@jumpNoteDownInCollection note
			else
				depthDifference = note.get('depth') - followingNote.get('depth')
				@unTabNote note for i in [depthDifference..1]
			note

		jumpFocusDown: (note) ->
			return followingNote if (followingNote = @findFollowingNote note)?
		jumpFocusUp: (note) ->
			return previousNote if (previousNote = @findPreviousNote note)?

		tabNote: (note) ->
			return false unless note.get('rank') > 1
			previousParentCollection = @getCollection note.get 'parent_id'
			parent = @findPrecedingInCollection note
			@removeFromCollection previousParentCollection, note
			note.save
				parent_id: parent.get 'guid'
				rank: parent.descendants.length + 1
				depth: 1 + note.get 'depth'
			@insertInTree note
		unTabNote: (note) ->
			return false if note.isARoot()
			previousParent = @getNote note.get 'parent_id'
			@removeFromCollection previousParent.descendants, note
			note.save
				parent_id: previousParent.get('parent_id')
				rank: previousParent.get('rank') + 1
				depth: note.get('depth') - 1
			@insertInTree note

		comparator: (note) ->
			note.get 'rank'

)
