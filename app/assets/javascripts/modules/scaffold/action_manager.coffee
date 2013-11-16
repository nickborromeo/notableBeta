
@Notable.module("Action", (Action, App, Backbone, Marionette, $, _) ->

	_undoStack = []
	_redoStack = []
	_historyLimit = 100
	_revert =  {}
	_addAction = {}


	## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#    expect to delete this:
	## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	_expects = 
		createNote: ['guid'] #only needs GUID to erase
		deleteBranch: ['ancestorNote','childNoteSet']
		moveNote: ['guid','depth','rank','parent_id']
		updateContent: ['guid','title','subtitle'] 
		# combinedAction: [flag!!!!, number of steps]  <<<<<<<<<<<<<<<<<<<<<<<<<<

		checker: (actionType, changes) ->
			return false unless @[actionType]?
			return false unless changes?
			for property in @[actionType]
				return false unless changes[property]?
			return true 
	## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#    end expect to delete.
	## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	# NOTES AND EXPLANATION:
	# -- all undo histories have a action TYPE, and CHANGE 
	#   	history item example: {type: '<<undoActionType>>', change: {object containing only relevant change info} }
	#	-- at the beginning of each undo action should be a list of EXPECTS 
	# 		(attributes expected to be found in 'change')
	# -- the usual pattern for updating changes is:
	#			1 - get note reference
	#			2 - remove note from tree
	#			3 - save new attributes
	#			4 - insert the note again
	#  		5 - reset focus on the correct note
	#			-- to improve the pattern for SOME actions only ie: content updates,
	# 					1 - save new attributes



	# -----------------------------
	# undo create notes
	# -----------------------------
	# EXPECTS change: {guid: guid}
	_addAction.createNote = (note) ->
		Action.addHistory 'createNote', {guid: note.get('guid')}



	_revert.createNote = (change) ->
		reference = _getReference(change.guid)

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


	# -----------------------------
	# undo deleted branch
	# -----------------------------
	_addAction.deleteBranch = (note) ->
		addUndoDelete: =>
			removedBranchs = {ancestorNote: @getAllAtributes(), childNoteSet: []}
			completeDescendants = @getCompleteDescendantList()
			_.each completeDescendants, (descendant) ->
				removedBranchs.childNoteSet.push(descendant.getAllAtributes())
			App.Action.addHistory('deleteBranch', removedBranchs)
			App.Notify.alert 'deleted', 'warning'



	_revert.reverseDeleteNote = (attributes) ->
		newBranch = new App.Note.Branch()
		newBranch.save(attributes)
		App.Note.tree.insertInTree newBranch
		#remove from storage if offline
		App.OfflineAccess.addToDeleteCache attributes.guid, false
		App.Note.eventManager.trigger "setCursor:#{newBranch.get('guid')}"			

	_revert.deleteBranch = (change) ->
		@reverseDeleteNote(change.ancestorNote)
		for attributes in change.childNoteSet
			@reverseDeleteNote(attributes)
		return {type: 'createNote', changes: { guid: change.ancestorNote.guid }}


	# -----------------------------
	# undo move note
	# -----------------------------

	_addAction.moveNote = (note) ->
		addUndoMove: =>
			App.Action.addHistory 'moveNote', {
				guid: @get('guid')
				parent_id: @get('parent_id')
				depth: @get('depth')
				rank: @get('rank')}


	_revert.moveNote = (change) ->
		reference = _getReference(change.guid)

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


	# -----------------------------
	# undo note content update
	# -----------------------------
	_addAction.updateContent = (note) ->
		addUndoUpdate: (newTitle, newSubtitle) =>
			#incase this update comes before timeout
			if @timeoutAndSaveID? then clearTimeout @timeoutAndSaveID 
			App.Action.addHistory 'updateContent', {
				guid: @get('guid')
				title: @get('title')
				subtitle: @get('subtitle')}


	_revert.updateContent = (change) ->
		reference = _getReference(change.guid)

		changeTemp =
			guid: change.guid
			title: reference.note.get('title')
			subtitle: reference.note.get('subtitle')

		App.Note.tree.removeFromCollection reference.parentCollection, reference.note
		reference.note.save change
		App.Note.tree.insertInTree reference.note

		App.Note.eventManager.trigger "setCursor:#{reference.note.get('guid')}"
		return {type: 'updateContent', changes: changeTemp}


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


	# --------------------------------------------------
	#   LOCAL STORAGE / CACHED CHANGES HELPERS
	# --------------------------------------------------

	# @exportToLocalStorage = ->
	# 	window.localStorage.setItem 'actionHistory', JSON.stringify _undoStack

	Action.addInitializer ->
		console.log 'starting action manager'
		_undoStack = JSON.parse(window.localStorage.getItem('actionHistory')) ? []

	# as great as this idea is, it won't always work... 
	Action.addFinalizer ->
		console.log 'ending action manager'
		_redoStack = window.localStorage.setItem 'actionHistory', JSON.stringify _undoStack

)