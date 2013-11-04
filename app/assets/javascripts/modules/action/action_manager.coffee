#TODO:  attempt to propery connect the model's add, remove, change, move
#TODO:  write test!!!!!!!
#FIXME:  deleting an ancestor deletes children... really need to fix this.
#FIXME:  moving notes around changes subsequent notes as well....
			#  some how all notes need to be updated....   
			# if we CAREFULLY call the "moveNote method" this should be OKAY.
			# but may have unintented consequences

#TODO:  periodically 30s? update completedHistory localStorage cache 
#TODO:  history should be added on spacebar up

@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	_undoStack = []
	_redoStack = []
	_historyLimit = 100
	_tree = ''
	_allNotes = ''

	_expects = 
		createNote: ['guid'] #only needs GUID to erase
		deleteNote: ['note','options'] #needs all data
		deleteBranch: ['ancestorNote','childNoteSet']
		moveNote: ['guid','previous','current'] #previous & current expect = {title:"", subtitle:""}
		updateContent: ['guid','previous','current'] #previous & current= {depth:-, rank:-, parent_id:""}
		checker: (actionType, changes) ->
			return false unless @[actionType]?
			return false unless changes?
			for property in @[actionType]
				return false unless changes[property]?
			return true 
	

	_revert = 
		createNote: (tree, change) ->
			noteReference = _allNotes.findWhere({guid: change.guid})
			noteAttributes = noteReference.getAllAtributes()
			_allNotes.remove noteReference
			_tree.deleteNote noteReference
			return {type: 'deleteNote', changes: {note: noteAttributes, options: {} } }

		deleteNote: (tree, change) ->
			newBranch = new App.Note.Branch()
			newBranch.save change.note
			_allNotes.add newBranch
			_tree.add newBranch
			return {type: 'createNote', changes: { guid: change.note.guid }}

		# deleteWholeBranch: (tree, change) ->
		# 	tree.insertInTree change.ancestorNote
		# 	for note in change.childNoteSet
		# 		tree.insertInTree note
		# 	return {type: 'createNote', changes: { guid: change.ancestorNote.guid }}

		moveNote: (tree, change) ->
			noteReference = tree.findNote change.guid
			noteReference.save(change.previous)
			# tree.removeFromCollection tree, noteReference
			tree.add noteReference
			return {type: 'moveNote', changes: @_swapPrevAndCurrent(change)}

		updateContent: (tree, change) ->
			noteReference = tree.findNote change.guid
			noteReference.save(change.previous)
			return {type: 'updateContent', changes: @_swapPrevAndCurrent(change)}

		_swapPrevAndCurrent: (change) ->
			tempSwap = {}
			tempSwap['guid'] = change.guid
			tempSwap['previous'] = change.current
			tempSwap['current'] = change.previous
			return tempSwap

		_setAttributes: (noteReference, attr) ->
			noteReference.save(attr)
			for key, val of attr
				noteReference.set key, val
			return noteReference

			#only for tests:

	clearundoneHistory = ->
		# undoneHistory.reverse()
		# for item in undoneHistory
		#   actionHistory.push undoneHistory.pop()
		_undoneHistory = []

	# ----------------------
	# Public Methods & Functions
	# ----------------------
	@addHistory = (actionType, changes) ->
		throw "!!--cannot track this change--!!" unless _expects.checker(actionType, changes)
		if _redoStack.length > 1 then clearundoneHistory()
		if _undoStack.length >= _historyLimit then _undoStack.shift()
		_undoStack.push {type: actionType, changes: changes}

	@undo = (tree) ->
		throw "nothing to undo" unless _undoStack.length > 0
		change = _undoStack.pop()
		_redoStack.push _revert[change.type](tree, change.changes)

	@redo = (tree) ->
		throw "nothing to redo" unless _redoStack.length > 0
		change = _redoStack.pop()
		_undoStack.push _revert[change.type](tree, change.changes)

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