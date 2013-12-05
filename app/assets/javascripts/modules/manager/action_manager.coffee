
@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	# NOTES AND EXPLANATION:
	# -- all undo histories have a action TYPE, and CHANGE 
	#   	history item example: {type: '<<undoActionType>>', change: {object containing only relevant change info} }
	#	-- at the beginning of each undo action should be a list of EXPECTS 
	# 		(attributes expected to be found in 'change')
	# -- the general pattern for updating changes is:
	#			1 - get note reference
	#  		2 - add inverse action to redoStack
	#			3 - remove note from tree
	#			4 - update with attributes
	#			5 - insert the note again
	#  		6 - reset focus on the correct note
	#		-***- to improve the pattern for SOME actions only ie: content updates, don't remove or add, just trigger update

	_undoStack = []
	_redoStack = []
	_historyLimit = 100
	_revert =  {}
	_addAction = {}

	# -----------------------------
	# Action: createNote
	# -----------------------------
	# EXPECTS change: {guid: guid}

	_addAction.createNote = (note, isUndo = false) ->
		history = { type: 'createNote', changes: {guid: note.get('guid') } }
		if isUndo then _redoStack.push(history) else _undoStack.push(history)

	_revert.createNote = (change, isUndo = true) ->
		reference = _getReference(change.guid)
		_addAction.deleteBranch reference.note, isUndo
		noteToFocusOn = App.Note.tree.jumpFocusUp(reference.note) ? App.Note.tree.jumpFocusDown(reference.note)
		App.Note.tree.deleteNote reference.note, true
		App.Note.eventManager.trigger "setCursor:#{noteToFocusOn.get('guid')}"


	# -----------------------------
	# undo deleted branch
	# -----------------------------
	# EXPECTS change: {ancestorNote: {<ancestorNote attributes>}, childNoteSet: [list of child notes + attributes] }

	_addAction.deleteBranch = (note, isUndo = false) ->
		removedBranchs = {ancestorNote: note.getAllAtributes(), childNoteSet: []}
		completeDescendants = note.getCompleteDescendantList()
		_.each completeDescendants, (descendant) ->
			removedBranchs.childNoteSet.push(descendant.getAllAtributes())
			App.OfflineAccess.addToDeleteCache descendant.get('guid'), true  #<< this should be handled in .destroy()
		history = {type: 'deleteBranch', changes: removedBranchs}
		if isUndo then _redoStack.push(history) else _undoStack.push(history)
		# App.Action.addHistory('deleteBranch', removedBranchs)
		# App.Notify.alert 'deleted', 'warning'

	_revert.reverseDeleteNote = (attributes) ->
		newBranch = new App.Note.Branch()
		# newBranch.save attributes
		App.Action.orchestrator.triggerAction 'createBranch', newBranch, attributes, isUndo: true
		App.Note.tree.insertInTree newBranch
		#remove from storage if offline
		App.OfflineAccess.addToDeleteCache attributes.guid, false
		App.Note.eventManager.trigger "setCursor:#{newBranch.get('guid')}"			

	_revert.deleteBranch = (change, isUndo = true) ->
		_revert.reverseDeleteNote(change.ancestorNote)
		_addAction.createNote _getReference(change.ancestorNote.guid).note, isUndo		
		for attributes in change.childNoteSet
			@reverseDeleteNote(attributes)



	# -----------------------------
	# undo move note
	# -----------------------------
	# EXPECTS change: {guid:'', parent_id:'', rank:'', depth: ''}
	_addAction.moveNote = (note, isUndo = false) ->
		history = {type: 'moveNote', changes: note.getPositionAttributes()}
		if isUndo then _redoStack.push(history) else _undoStack.push(history)

	_revert.moveNote = (change, isUndo = true) ->
		reference = _getReference(change.guid)
		_addAction.moveNote reference.note, isUndo

		App.Note.tree.removeFromCollection reference.parentCollection, reference.note
		# reference.note.save change
		App.Action.orchestrator.triggerAction 'basicAction', reference.note, change, isUndo: isUndo
		App.Note.tree.insertInTree reference.note

		App.Note.eventManager.trigger "setCursor:#{reference.note.get('guid')}"



	# -----------------------------
	# undo note content update
	# -----------------------------
	# EXPECTS change: {guid: '', title:'', subtitle:''}
	_addAction.updateContent = (note, isUndo = false) ->
		history = {type: 'updateContent', changes: note.getContentAttributes()}
		if isUndo then _redoStack.push(history) else _undoStack.push(history)

	_revert.updateContent = (change, isUndo = true) ->
		reference = _getReference(change.guid)
		_addAction.updateContent reference.note, isUndo
		App.Action.orchestrator.triggerAction 'updateContent', reference.note, change, isUndo: isUndo
		App.Note.eventManager.trigger "setTitle:#{change.guid}", change.title
		# App.Note.eventManager.trigger "setSubtitle:#{change.guid}", change.subtitle

	# -----------------------------
	# undo compoundAction
	# -----------------------------
	# EXPECTS change: {actions: 'number'}

	_addAction.compoundTargets = [] #this is a list of targets to listen
 	# each item in targets needs to be {actions:, count:, isUndo:}

	_addAction.compoundAction = (options, isUndo = false) ->
		if !!options.previousActions then _addAction.compoundActionCreator options.actions, isUndo
		else _addAction.compoundTargets.push 
			actions: options.actions
			count: options.actions
			isUndo: isUndo

	_addAction.compoundTrigger = ->
		if _addAction.compoundTargets.length > 0
			_(_addAction.compoundTargets).each (target, index, fullList) ->
				target.count--
				if target.count is 0
					_addAction.compoundActionCreator target.actions, target.isUndo
					delete fullList[index]
			_addAction.compoundTargets = _(_addAction.compoundTargets).reject (item) -> return item is undefined

	_addAction.compoundActionCreator = (actions, isUndo = false) ->
		history = {type:'compoundAction', changes: {actions: actions}}
		if isUndo then _redoStack.push(history) else _undoStack.push(history)

	_revert.compoundAction = (change, isUndo = true) ->
		if isUndo
			Action.undo() for i in [change.actions..1]
		else
			Action.redo() for i in [change.actions..1]
		_addAction.compoundActionCreator change.actions, isUndo


	# -----------------------------
	#   HELPERS
	# -----------------------------

	_getReference = (guid) ->
		note = App.Note.tree.findNote(guid)
		parent_id = note.get('parent_id')
		parentCollection = App.Note.tree.getCollection(parent_id)
		{note: note, parent_id: parent_id, parentCollection: parentCollection}

	clearRedoHistory = ->
		# _redoStack.reverse()
		# for item in _redoStack
		#   actionHistory.push _redoStack.pop()
		_redoStack = []



	# ----------------------
	# Public Methods & Functions
	# ----------------------

	# currently compoundAction is the only type that takes an OBJECT with {actions: }  and optionally previousActions
	@addHistory = (actionType, note, isUndo = false) ->
		# console.log "Adding to history", actionType, note
		throw "!!--cannot track this change--!!" unless _addAction[actionType]?
		throw "compoundAction takes an object with an integer!" if actionType is "compoundAction" and isNaN(note.actions)
		clearRedoHistory() if _redoStack.length > 1 and isUndo is false
		if _undoStack.length >= _historyLimit then _undoStack.shift()
		_addAction[actionType] note, isUndo
		_addAction.compoundTrigger() unless actionType is "compoundAction"
	
	@undo = ->
		throw "nothing to undo" unless _undoStack.length > 0
		change = _undoStack.pop()
		# console.log "Stack", _undoStack, change.type, change.change
		_revert[change.type](change.changes)
		

	@redo = ->
		throw "nothing to redo" unless _redoStack.length > 0
		change = _redoStack.pop()
		console.log "Stack", _redoStack, change.type, change.changes
		_revert[change.type](change.changes, false)

	@setHistoryLimit = (limit) ->
		throw "-- cannot set #{limit} " if isNaN limit
		_historyLimit = limit

	@getHistoryLimit = ->
		_historyLimit


	# -----------------------------
	#   TEST HELPERS -- don't erase or you break tests
	# -----------------------------

	@_getActionHistory = ->
		_undoStack

	@_getUndoneHistory = ->
		_redoStack

	@_resetActionHistory = ->
		_undoStack = []
		_redoStack = []



	# --------------------------------------------------
	#   LOCAL STORAGE / CACHED CHANGES HELPERS
	# --------------------------------------------------

	# @exportToLocalStorage = ->
	# 	window.localStorage.setItem 'actionHistory', JSON.stringify _undoStack

	Action.addInitializer ->
		console.log 'starting action manager'
		_undoStack = JSON.parse(window.localStorage.getItem('actionHistory')) ? []

	# as great as this idea is, it won't (always) work... 
	Action.addFinalizer ->
		console.log 'ending action manager'
		_redoStack = window.localStorage.setItem 'actionHistory', JSON.stringify _undoStack

)
