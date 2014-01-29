@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	Action.defaultAction = (branch, attributes, options = {}) ->
		branch: branch
		attributes: attributes
		previous_attributes: branch.attributes
		options: options
		compound: ->
		addToHistory: ->
		triggerNotification: ->
		destroy: false
		specificActions: ->

	Action.buildAction = (actionType, branch, attributes, options = {}) ->
		args = App.Note.sliceArgs arguments
		_(Action[actionType].apply @, args).defaults(Action.defaultAction.apply @, args)

	# Action Types: basicActipn, mergeWithPreceding, deleteBranch, createBranch, updateBranch
	Action.basicAction = -> {}

	Action.mergeWithPreceding = (branch, attributes, options = {}) ->
		_(
			compound: -> unless options.isUndo then App.Action.manager.addHistory 'compoundAction', {actions: 2}
			triggerNotification: ->
		).defaults(Action.buildAction('deleteBranch', branch, attributes, options))

	Action.deleteBranch = (branch, attributes, options = {}) ->
		addToHistory:	-> unless options.isUndo then App.Action.manager.addHistory 'deleteBranch', branch
		triggerNotification: -> unless options.isUndo then App.Notify.alert 'deleted', 'warning'
		destroy: true

	Action.createBranch = (branch, attributes, options = {}) ->
		# compound: -> unless options.isUndo then App.Action.manager.addHistory "compoundAction", {actions:2}
		addToHistory: -> unless options.isUndo then App.Action.manager.addHistory 'createBranch', branch
		specificActions: ->	App.Note.tree.insertInTree branch

	Action.updateBranch = (branch, attributes, options = {}) ->
		addToHistory: -> App.Action.manager.addHistory 'updateBranch', branch, options.isUndo

	class Action.Orchestrator

		constructor: ->
			@destroyQueue = []
			App.Note.eventManager.on "syncingDone", @validateChanges.bind(@), @
		queueDestroy: (action) ->
			@destroyQueue.push action.branch
		triggerAction: (actionType, branch, attributes, options = {}) ->
			@clearSavingQueueTimeout()
			action = Action.buildAction.apply(@, arguments)
			@queueDestroy action if action.destroy
			@processAction action
		triggerSaving: (callback) ->
			@callback = callback if callback?
			@clearSavingQueueTimeout()
			@syncWithLocal()

		processAction: (action) ->
			action.compound()
			action.addToHistory()
			action.triggerNotification()
			action.branch.set action.attributes if action.attributes?
			Action.transporter.addToStorage(action) unless action.options.noLocalStorage
			action.specificActions()
		validate: (branch, attributes, options) ->
			return false if (val = branch.validation attributes)?
			true

		clearSavingQueueTimeout: ->
			clearTimeout @savingQueueTimeout
		startSavingQueueTimeout: ->
			@savingQueueTimeout = setTimeout @syncWithLocal.bind(@), 5000

		syncWithLocal: ->
			Action.transporter.testServerConnection()
		validateChanges: ->
			try
				App.Note.allNotesByDepth.validateTree()
			catch e
				console.log e
				@rejectChanges()
			@acceptChanges()
		rejectChanges: ->
			App.Note.noteController.reset()
			Action.transporter.storage.clear()
			App.Notify.alert 'brokenTree', 'danger'
		acceptChanges:  ->
			Action.transporter.processToServer @callback
			@callback = undefined
