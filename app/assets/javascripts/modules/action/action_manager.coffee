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

	Action.stack = {}
	Action.stack.redo = []
	Action.stack.undo = []

	class Action.Manager  #Action.HistoryManager

		constructor: ->
			@undoStack = Action.stack.redo
			@redoStack = Action.stack.undo
			@historyLimit = 100
			@revert = @initializeRevert()								#initiaizeHistory (?)
			@revertActions = new Action.RevertActions   #Action.RedoActions
			@addAction = new Action.HistoryActions			#Action.UndoActions

		initializeRevert: ->
			###
			createAction: (branch, isUndo=true) =>
				branchData = Action.Helpers.getBranchData(branch.guid)
				@UndoActions.deleteBranch branch.note, isUndo
				@RedoActions.createBranch.apply(@revertActions, arguments)
			###
			createBranch: (change, isUndo = true) =>
				reference = Action.Helpers.getReference(change.guid)
				@addAction.deleteBranch reference.note, isUndo
				@revertActions.createBranch.apply(@revertActions, arguments)
			deleteBranch: (change, isUndo = true) =>
				@revertActions.deleteBranch.apply(@revertActions, arguments)
				@addAction.createBranch Action.Helpers.getReference(change.ancestorNote.guid).note, isUndo
			moveBranch: (change, isUndo = true) =>
				reference = Action.Helpers.getReference(change.guid)
				@addAction.moveBranch reference.note, isUndo
				@revertActions.moveBranch.apply(@revertActions, arguments)
			updateBranch: (change, isUndo = true) =>
				reference = Action.Helpers.getReference(change.guid)
				@addAction.updateBranch reference.note, isUndo
				@revertActions.updateBranch.apply(@revertActions, arguments)
			compoundAction: (change, isUndo = true) =>
				@addAction.compoundActionCreator change.actions, isUndo
				@revertActions.compoundAction.apply(@revertActions, arguments)

		clearRedoHistory: ->
			# @redoStack.reverse()
			# for item in @redoStack
			#   actionHistory.push @redoStack.pop()
			@redoStack = []

		addHistory: (actionType, note, isUndo = false) ->
			throw "!!--cannot track this change--!!" unless @addAction[actionType]?
			throw "compoundAction takes an object with an integer!" if actionType is "compoundAction" and isNaN(note.actions)
			@clearRedoHistory() if @redoStack.length > 1 and isUndo is false
			if @undoStack.length >= @historyLimit then @undoStack.shift()
			@addAction[actionType] note, isUndo
			@addAction.compoundTrigger() unless actionType is "compoundAction"

		undo: ->
			throw "nothing to undo" unless @undoStack.length > 0
			change = @undoStack.pop()
			@revert[change.type](change.changes)

		redo: ->
			throw "nothing to redo" unless @redoStack.length > 0
			change = @redoStack.pop()
			@revert[change.type](change.changes, false)

		setHistoryLimit: (limit) ->
			throw "-- cannot set #{limit} " if isNaN limit
			@historyLimit = limit

		getHistoryLimit: ->
			@historyLimit

		# -----------------------------
		#   TEST HELPERS -- don't erase or you break tests
		# -----------------------------

		getActionHistory: ->
			@undoStack

		getUndoneHistory: ->
			@redoStack

		resetActionHistory: ->
			@undoStack = []
			@redoStack = []

	class Action.HistoryActions

		constructor: ->
			@undoStack = Action.stack.redo
			@redoStack = Action.stack.undo
			@compoundTargets = [] #this is a list of targets to listen
		 	# each item in targets needs to be {actions:, count:, isUndo:}

		createBranch: (note, isUndo = false) ->
			history = { type: 'createBranch', changes: {guid: note.get('guid') } }
			if isUndo then @redoStack.push(history) else @undoStack.push(history)
		deleteBranch: (note, isUndo = false) ->
			removedBranches = {ancestorNote: note.getAllAtributes(), childNoteSet: []}
			completeDescendants = note.getCompleteDescendantList()
			_.each completeDescendants, (descendant) ->
				removedBranches.childNoteSet.push(descendant.getAllAtributes())
				Action.storage.addDelete descendant, true  #       << this should be handled in .destroy()
			history = {type: 'deleteBranch', changes: removedBranches}
			if isUndo then @redoStack.push(history) else @undoStack.push(history)
		moveBranch: (note, isUndo = false) ->
			history = {type: 'moveBranch', changes: note.getPositionAttributes()}
			if isUndo then @redoStack.push(history) else @undoStack.push(history)
		updateBranch: (note, isUndo = false) ->
			history = {type: 'updateBranch', changes: note.getContentAttributes()}
			if isUndo then @redoStack.push(history) else @undoStack.push(history)

		compoundAction: (options, isUndo = false) ->
			if !!options.previousActions then @compoundActionCreator options.actions, isUndo
			else @compoundTargets.push
				actions: options.actions
				count: options.actions
				isUndo: isUndo
		compoundTrigger: ->
			if @compoundTargets.length > 0
				_(@compoundTargets).each (target, index, fullList) =>
					target.count--
					if target.count is 0
						@compoundActionCreator target.actions, target.isUndo
						delete fullList[index]
				@compoundTargets = _(@compoundTargets).reject (item) -> return item is undefined
		compoundActionCreator: (actions, isUndo = false) ->
			history = {type:'compoundAction', changes: {actions: actions}}
			if isUndo then @redoStack.push(history) else @undoStack.push(history)

	class Action.RevertActions

		# EXPECTS change: {guid: guid}
		createBranch: (change, isUndo = true) ->
			reference = Action.Helpers.getReference(change.guid)
			noteToFocusOn = App.Note.tree.jumpFocusUp(reference.note) ? App.Note.tree.jumpFocusDown(reference.note)
			App.Note.tree.deleteNote reference.note, true
			App.Note.eventManager.trigger "setCursor:#{noteToFocusOn.get('guid')}"


		# EXPECTS change: {ancestorNote: {<ancestorNote attributes>}, childNoteSet: [list of child notes + attributes] }
		deleteBranch: (change, isUndo = true) ->
			@reverseDeleteBranch(change.ancestorNote)
			for attributes in change.childNoteSet
				@reverseDeleteBranch(attributes)
		reverseDeleteBranch: (attributes) ->
			newBranch = new App.Note.Branch()
			App.Action.orchestrator.triggerAction 'createBranch', newBranch, attributes, isUndo: true
			App.Note.tree.insertInTree newBranch
			#remove from storage if offline
			Action.storage.addDelete newBranch, false
			App.Note.eventManager.trigger "setCursor:#{newBranch.get('guid')}"

		# EXPECTS change: {guid:'', parent_id:'', rank:'', depth: ''}
		moveBranch: (change, isUndo = true) ->
			reference = Action.Helpers.getReference(change.guid)
			App.Note.tree.removeFromCollection reference.parentCollection, reference.note
			App.Action.orchestrator.triggerAction 'basicAction', reference.note, change, isUndo: isUndo
			App.Note.tree.insertInTree reference.note
			App.Note.eventManager.trigger "setCursor:#{reference.note.get('guid')}"

		# EXPECTS change: {guid: '', title:'', subtitle:''}
		updateBranch: (change, isUndo = true) ->
			reference = Action.Helpers.getReference(change.guid)
			App.Action.orchestrator.triggerAction 'updateBranch', reference.note, change, isUndo: isUndo
			App.Note.eventManager.trigger "setTitle:#{change.guid}", change.title
			# App.Note.eventManager.trigger "setSubtitle:#{change.guid}", change.subtitle

		# EXPECTS change: {actions: 'number'}
		compoundAction: (change, isUndo = true) ->
			if isUndo
				Action.manager.undo() for i in [change.actions..1]
			else
				Action.manager.redo() for i in [change.actions..1]

	Action.addInitializer ->
		Action.stack.undo = JSON.parse(window.localStorage.getItem('actionHistory')) ? []

	# as great as this idea is, it won't (always) work...
	Action.addFinalizer ->
		Action.stack.redo = window.localStorage.setItem 'actionHistory', JSON.stringify @undoStack

)
