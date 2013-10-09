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

		isARoot: ->
			@get('parent_id') is 'root'
		isInSameCollection: (note) ->
			@get('parent_id') is note.get('parent_id')

		getCompleteDescendantList: ->
			list = []
			rec = (current, rest) =>
				return unless current?
				list.push current
				if current.descendants.length isnt 0
					rec current.descendants.first(), current.descendants.rest()
				rec _.first(rest), _.rest rest
			rec @descendants.first(), @descendants.rest()
			list
		firstDescendant: ->
			@descendants.models[0]


		clonableAttributes: ['depth', 'rank', 'parent_id']
		cloneNote: (noteToClone) ->
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
		increaseDescendantsDepth: (magnitude = 1) -> @modifyDescendantsDepth increaseDepthOfNote magnitude
		decreaseDescendantsDepth: (magnitude = 1) -> @modifyDescendantsDepth decreaseDepthOfNote magnitude
		modifyDescendantsDepth: (applyFunction) ->
			descendants = @getCompleteDescendantList()
			_.each descendants, applyFunction

	# Static Function
	Note.Model.generateAttributes = (precedentNote, text) ->
		title: text
		rank: 1 + precedentNote.get 'rank'
		parent_id: precedentNote.get 'parent_id'
		depth: precedentNote.get 'depth'

	# Helper Functions (to be moved)
	# For use as a higher order function
	increaseRankOfNote = (note) -> note.increaseRank()
	decreaseRankOfNote = (note) -> note.decreaseRank()
	increaseDepthOfNote = (magnitude = 1) -> (note) -> note.increaseDepth(magnitude)
	decreaseDepthOfNote = (magnitude = 1) -> (note) -> note.decreaseDepth(magnitude)

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
		findByGuidInCollection: (guid) ->
			noteSearched = false
			@every (note) ->
				if note.get('guid') is guid
					noteSearched = note
					false # break
				else
					true # continue
			noteSearched

		forEachInFilteredCollection: (parent_id, applyFunction, filterFunction = false) ->
			collection = @getCollection parent_id
			filteredNotes	= collection.filter filterFunction unless !filterFunction
			_.each filteredNotes, applyFunction, this

		filterFollowingNotes: (self) ->
			(comparingNote) ->
				self.get('rank') <= comparingNote.get('rank') and self.get('guid') isnt comparingNote.get('guid')
		modifyRankOfFollowing: (self, applyingFunction) -> @forEachInFilteredCollection self.get('parent_id'), applyingFunction, @filterFollowingNotes(self)
		increaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, increaseRankOfNote
		decreaseRankOfFollowing: (self) -> @modifyRankOfFollowing self, decreaseRankOfNote

		findPreviousNoteInCollection: (note) ->
			currentCollection = @getCollection note.get 'parent_id'
			currentCollection.findFirstInCollection rank: note.get('rank') - 1
		findPreviousNote: (note) ->
			return undefined if (note.isARoot() and note.get('rank') is 1)
			if note.get('rank') is 1
				return @getNote(note.get('parent_id'))
			previousNote = @findPreviousNoteInCollection note
			if previousNote.descendants.length is 0
				return previousNote
			previousNote.getCompleteDescendantList()[-1..][0]
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
			previousNote = @findPreviousNoteInCollection note
			note.decreaseRank()
			previousNote.increaseRank()
			@getCollection(note.get 'parent_id').sort()
		jumpNoteDownInCollection: (note) ->
			followingNote = @findFollowingNoteInCollection note
			return undefined unless followingNote?
			followingNote.decreaseRank()
			note.increaseRank()
			@getCollection(note.get 'parent_id').sort()
		jumpNoteUp: (note) ->
			previousNote = @findPreviousNote note
			if note.isInSameCollection previousNote
				@jumpNoteUpInCollection note
			else if (depthDifference = previousNote.get('depth') - note.get('depth')) > 0
				@tabNote note for i in [depthDifference..1]
			else
				previousCollection = @getCollection note.get 'parent_id'
				@removeFromCollection previousCollection, note
				note.cloneNote previousNote
				@insertInTree note
				note
		jumpNoteDown: (note) ->
			followingNote = @findFollowingNote note, false
			if note.isInSameCollection followingNote
				@jumpNoteDownInCollection note
			else
				depthDifference = note.get('depth') - followingNote.get('depth')
				@unTabNote note for i in [depthDifference..1]
			note

		jumpFocusToFollowingNote: (note) ->
			return followingNote if (followingNote = @findFollowingNote note)?
		jumpFocusToPreviousNote: (note) ->
			return previousNote if (previousNote = @findPreviousNote note)?	

		createNote: (precedentNote, text) ->
			@increaseRankOfFollowing precedentNote
			@create Note.Model.generateAttributes(precedentNote, text)
		deleteNote: (note) ->
			pid = note.get 'parent_id'
			rank = note.get 'rank' 
			descendants = note.getCompleteDescendantList()
			_.each descendants, (descendant) ->
				descendant.destroy()
			self = note
			note.destroy success: @decreaseRankOfFollowing self

		tabNote: (note) ->
			return false unless note.get('rank') > 1
			previousParentCollection = @getCollection note.get 'parent_id'
			parent = @findPreviousNoteInCollection note
			@removeFromCollection previousParentCollection, note
			note.save
				parent_id: parent.get 'guid'
				rank: parent.descendants.length + 1
				depth: 1 + note.get 'depth'
			@insertInTree note
		unTabNote: (note) ->
			return false unless note.get('depth') > 0
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
