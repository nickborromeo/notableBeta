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
			@changeQueue = []
			@destroyQueue = []
			App.Note.eventManager.on "syncingDone", @validateChanges.bind(@), @

		queueChange: (action) ->
			@changeQueue.push action
		queueDestroy: (action) ->
			@destroyQueue.push action.branch
			@processAction action
		triggerAction: (actionType, branch, attributes, options = {}) ->
			@clearSavingQueueTimeout()
			action = Action.buildAction.apply(@, arguments)
			if action.destroy
				@queueDestroy action
				@startSavingQueueTimeout()
			else
				@queueChange action
				@processChangeQueue()
		triggerSaving: (callback) ->
			@callback = callback if callback?
			interval = setInterval =>
				@clearSavingQueueTimeout()
				if not @processingActions and @changeQueue.length is 0
					clearInterval interval
					@syncWithLocal()

		processChangeQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @changeQueue.shift()) =>
				return if not action? # continue to process and validate actions if there are any left in the changeQueue
				@processAction action
				rec @changeQueue.shift()
			@processingActions = false
			@startSavingQueueTimeout()
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
