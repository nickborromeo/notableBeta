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

	Action.updateBranch = (branch, attributes, options = {}) ->
		addToHistory: -> App.Action.manager.addHistory 'updateBranch', branch, options.isUndo

	class Action.Orchestrator

		constructor: ->
			@changeQueue = []
			@destroyQueue = []
			@validationQueue = []
			@savingQueue = []

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
		triggerSaving: ->
			interval = setInterval =>
				@clearSavingQueueTimeout()
				if not @processingActions and @changeQueue.length is 0
					clearInterval interval
					@processValidationQueue()

		processChangeQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @changeQueue.shift()) =>
				return if not action?  # continue to process and validate actions if there are any left in the changeQueue
				# action.branch.set action.attributes
				@processAction action
				@validationQueue.push action
				rec @changeQueue.shift()
			@processingActions = false
			@startSavingQueueTimeout()
		processAction: (action) ->
			action.compound()
			action.addToHistory()
			action.triggerNotification()
			action.branch.set action.attributes if action.attributes?
			unless action.options.noLocalStorage
				if action.destroy
					Action.storage.addDelete action.branch
				else
					Action.storage.addChange action.branch

		validate: (branch, attributes, options) ->
			return false if (val = branch.validation attributes)?
			true

		clearSavingQueueTimeout: ->
			clearTimeout @savingQueueTimeout
		startSavingQueueTimeout: ->
			@savingQueueTimeout = setTimeout @processValidationQueue.bind(@), 5000
		processValidationQueue: () ->
			valid = true
			savingQueue = []
			# console.log "Complete validation Queue"
			# _.each @validationQueue, (v) ->
			# 	console.log v.branch.get('guid'), v.branch.id, "Sent attributes", v.attributes, "branch attributes", v.branch.attributes
			@validationQueue = @mergeValidQueue @validationQueue
			# console.log "Trimed validation queue", @validationQueue
			# console.log "validation queue", @validationQueue
			do rec = (branch = @validationQueue.shift()) =>
				return if not branch? or not valid
				# console.log "Validation", branch.get('guid'), branch.id, branch.attributes
				if not @validate branch, branch.attributes
					return valid = false
				savingQueue.push branch
				# console.log branch.get('guid'), "validated"
				rec @validationQueue.shift()
			if valid then @acceptChanges(savingQueue) else @rejectChanges(savingQueue)
		mergeValidQueue: (validQueue) ->
			guids = []
			queue = []
			_.each validQueue, (obj) =>
				if obj.branch.get('guid') not in guids and obj.branch not in @destroyQueue
					guids.push obj.branch.get('guid')
					queue.push obj.branch
			queue

		rejectChanges: (validQueue) ->
			@validationQueue = []
			App.Note.noteController.reset()
			Action.storage.clear()
			App.Notify.alert 'brokenTree', 'danger'
		acceptChanges: (validQueue) ->
			return if Action.transporter.isOffline()
			# console.log "accept changes", validQueue
			@processDestroy()
			App.Notify.alert 'saving', 'save'
			# console.log "trimed changes", validQueue
			do rec = (branch = validQueue.shift()) ->
				return if not branch?
				branch.save null,
					success: -> if validQueue.length is 0 then Action.storage.clear(); App.Notify.alert 'saved', 'save'
					doNotAddToLocal: true
				rec validQueue.shift()
		processDestroy: ->
			# console.log "destroyQueue", @destroyQueue
			do rec = (branch = @destroyQueue.shift()) =>
				return if not branch?
				if branch.id?
					branch.destroy()
				rec @destroyQueue.shift()
