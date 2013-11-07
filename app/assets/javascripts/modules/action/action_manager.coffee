#FIXME:  notes have updated information, but are not re-rendered in the view!

@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	_undoStack = []
	_redoStack = []
	_historyLimit = 100
	_tree = ''
	_allNotes = ''

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
				removedBranchs.childNoteSet.push(descendant.getAllAtributes())

			_allNotes.remove reference.note
			_tree.deleteNote reference.note, true
			#trigger update view:
			return {type: 'deleteBranch', changes: removedBranchs }

		reverseDeleteNote: (attributes) ->
			newBranch = new App.Note.Branch()
			newBranch.save attributes
			_allNotes.add newBranch
			reference = @_getReference newBranch.get('guid')
			_tree.insertInTree newBranch
			# reference.parentCollection.add newBranch

		deleteBranch: (change) ->
			@reverseDeleteNote(change.ancestorNote)
			for attributes in change.childNoteSet
				@reverseDeleteNote(attributes)
			#trigger update view:
			return {type: 'createNote', changes: { guid: change.ancestorNote.guid }}

		moveNote: (change) ->
			reference = @_getReference(change.guid)

			changeTemp =
				guid: change.guid
				depth: reference.note.get('depth')
				rank: reference.note.get('rank')
				parent_id: reference.parent_id

			_tree.removeFromCollection reference.parentCollection, reference.note
			reference.note.save change
			_tree.insertInTree reference.note
			#trigger update view!!!!!!!!!!
			return {type:'moveNote', changes: changeTemp}

		updateContent: (change) ->
			reference = @_getReference(change.guid)

			changeTemp =
				guid: change.guid
				title: reference.note.get('title')
				subtitle: reference.note.get('subtitle')

			_tree.removeFromCollection reference.parentCollection, reference.note
			reference.note.save change
			_tree.insertInTree reference.note
			return {type: 'updateContent', changes: changeTemp}

		_getReference: (guid) ->
			note = @_findANote(guid)
			parent_id = note.get('parent_id')
			parentCollection = _tree.getCollection(parent_id)
			{note: note, parent_id: parent_id, parentCollection: parentCollection}

		_findANote: (guid) ->
			_allNotes.findWhere({guid: guid}) ? _tree.findNote(guid)

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

	@exportToServer = ->
		#do something if nessecary 

	@exportToLocalStorage = ->
		window.localStorage.setItem 'history', JSON.stringify(_undoStack)
	#moves items undone to the change completed change stack...

	@loadHistoryFromLocalStorage = ->
		loadPreviousActionHistory JSON.parse(window.localStorage.getItem('history'))

	@loadPreviousActionHistory = (previousHistory) ->
		throw "-- this is not history! --" unless Array.isArray previousHistory
		#warning = this will erase all previous history.
		_undoStack = previousHistory

	@setHistoryLimit = (limit) ->
		throw "-- cannot set #{limit} " if isNaN limit
		_historyLimit = limit

	@getHistoryLimit = ->
		_historyLimit

	@setTree = (tree) ->
		_tree = tree

	@setAllNotesByDepth = (allNotes) ->
		_allNotes = allNotes


	## !! this is for testing ONLY
	## don't try to erase... its deadly.
	@_getActionHistory = ->
		_undoStack

	@_getUndoneHistory = ->
		_redoStack

	@_resetActionHistory = ->
		_undoStack = []
		_redoStack = []

	@_getTree = ->
		_tree

	@_getNoteCollection = ->
		_allNotes

)