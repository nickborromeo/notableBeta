
@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	_undoStack = []
	_redoStack = []
	_historyLimit = 100

	_expects = 
		createNote: ['guid'] #only needs GUID to erase
		deleteBranch: ['ancestorNote','childNoteSet']
		moveNote: ['guid','depth','rank','parent_id']
		updateContent: ['guid','title','subtitle'] 
		checker: (actionType, changes) ->
			return false unless @[actionType]?
			return false unless changes?
			for property in @[actionType]
				return false unless changes[property]?
			return true 

	_revert = 
		createNote: (change) ->
			reference = @_getReference(change.guid)

			removedBranchs = {ancestorNote: reference.note.getAllAtributes(), childNoteSet: []}
			completeDescendants = reference.note.getCompleteDescendantList()
			_.each completeDescendants, (descendant) ->
				App.OfflineAccess.addToDeleteCache descendant.get('guid'), true
				removedBranchs.childNoteSet.push(descendant.getAllAtributes())

			App.Note.tree.deleteNote reference.note, true

			if reference.parent isnt 'root'
				App.Note.eventManager.trigger "setCursor:#{reference.parent_id}"
			else
				App.Note.eventManager.trigger "setCursor:#{App.Note.tree.first().get('guid')}"
			return {type: 'deleteBranch', changes: removedBranchs }

		reverseDeleteNote: (attributes) ->
			newBranch = new App.Note.Branch()
			newBranch.save attributes
			App.Note.allNotesByDepth.add newBranch
			# reference = @_getReference newBranch.get('guid')
			App.Note.tree.insertInTree newBranch
			App.Note.eventManager.trigger "setCursor:#{attributes.guid}"
			#remove from storage if offline
			App.OfflineAccess.addToDeleteCache attributes.guid, false

		deleteBranch: (change) ->
			@reverseDeleteNote(change.ancestorNote)
			for attributes in change.childNoteSet
				@reverseDeleteNote(attributes)
			return {type: 'createNote', changes: { guid: change.ancestorNote.guid }}

		moveNote: (change) ->
			reference = @_getReference(change.guid)

			changeTemp =
				guid: change.guid
				depth: reference.note.get('depth')
				rank: reference.note.get('rank')
				parent_id: reference.parent_id

			App.Note.tree.removeFromCollection reference.parentCollection, reference.note
			reference.note.save change
			App.Note.tree.insertInTree reference.note
			
			App.Note.eventManager.trigger "setCursor:#{reference.note.get('guid')}"
			return {type:'moveNote', changes: changeTemp}

		updateContent: (change) ->
			reference = @_getReference(change.guid)

			changeTemp =
				guid: change.guid
				title: reference.note.get('title')
				subtitle: reference.note.get('subtitle')

			App.Note.tree.removeFromCollection reference.parentCollection, reference.note
			reference.note.save change
			App.Note.tree.insertInTree reference.note

			App.Note.eventManager.trigger "setCursor:#{reference.note.get('guid')}"
			return {type: 'updateContent', changes: changeTemp}

		_getReference: (guid) ->
			note = @_findANote(guid)
			parent_id = note.get('parent_id')
			parentCollection = App.Note.tree.getCollection(parent_id)
			{note: note, parent_id: parent_id, parentCollection: parentCollection}

		_findANote: (guid) ->
			App.Note.allNotesByDepth.findWhere({guid: guid}) ? App.Note.tree.findNote(guid)

	clearRedoHistory = ->
		# _redoStack.reverse()
		# for item in _redoStack
		#   actionHistory.push _redoStack.pop()
		_redoStack = []

	# ----------------------
	# Public Methods & Functions
	# ----------------------
	@addHistory = (actionType, changes) ->
		throw "!!--cannot track this change--!!" unless _expects.checker(actionType, changes)
		if _redoStack.length > 1 then clearRedoHistory()
		if _undoStack.length >= _historyLimit then _undoStack.shift()
		_undoStack.push {type: actionType, changes: changes}

	@undo = ->
		throw "nothing to undo" unless _undoStack.length > 0
		change = _undoStack.pop()
		_redoStack.push _revert[change.type](change.changes)

	@redo = ->
		throw "nothing to redo" unless _redoStack.length > 0
		change = _redoStack.pop()
		_undoStack.push _revert[change.type](change.changes)
		if change.type is 'createNote' then App.Notify.alert 'deleted', 'warning'

	# @exportToLocalStorage = ->
	# 	window.localStorage.setItem 'history', JSON.stringify(_undoStack)
	# #moves items undone to the change completed change stack...

	# @loadHistoryFromLocalStorage = ->
	# 	loadPreviousActionHistory JSON.parse(window.localStorage.getItem('history'))

	# @loadPreviousActionHistory = (previousHistory) ->
	# 	throw "-- this is not history! --" unless Array.isArray previousHistory
	# 	#warning = this will erase all previous history.
	# 	_undoStack = previousHistory

	@setHistoryLimit = (limit) ->
		throw "-- cannot set #{limit} " if isNaN limit
		_historyLimit = limit

	@getHistoryLimit = ->
		_historyLimit

	## !! this is for testing ONLY
	## don't try to erase... its deadly.
	@_getActionHistory = ->
		_undoStack

	@_getUndoneHistory = ->
		_redoStack

	@_resetActionHistory = ->
		_undoStack = []
		_redoStack = []

)