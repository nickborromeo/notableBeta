@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->
	
	class Action.Orchestrator

		constructor: ->
			@savingQueue = []
			@actionQueue = []

		queueAction: (branch, attributes, options) ->
			# will probably have to play with the action manager
			@actionQueue.push
				branch: branch
				attributes: attributes
				previous_attributes: branch.attributes
				options: options
		triggerAction: (branch, attributes, options) ->
			clearTimeout @savingQueueTimeout
			@queueAction.apply(@, arguments)
			@processActionQueue()
			# @queueSaving attributes, branch

		processActionQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @actionQueue.shift()) =>
				return if not action?
				# if action.options.type is 'save'
				# return if not @validate action.branch, action.attributes
				# action.branch.save action.attributes, syncToServer: true, validate: false
				action.args = [action.attributes, syncToServer: true, validate: false]
				console.log "set", action.branch.attributes, action.attributes
				action.branch.set action.attributes
			 	# else if action.options.type is 'destroy'
				# 	action.branch.destroy syncToServer: true, validate: false
				# 	action.args = [syncToServer: true, validate: false]
				# Push action to history
				@savingQueue.push action
				console.log "savingQueue", @savingQueue
				rec @actionQueue.shift()
			@processingActions = false
			@startSavingQueueTimeout()

		validate: (branch, attributes, options) ->
			if (val = branch.validate attributes)?
				console.log val
				false
			else
				true

		startSavingQueueTimeout: ->
			@savingQueueTimeout = setTimeout @processSavingQueue.bind(@), 600
		processSavingQueue: () ->
			valid = true
			validQueue = []
			do rec = (action = @savingQueue.shift()) =>
				return if not action? or not valid
				console.log "processing savingQueue", action
				if not @validate action.branch, action.attributes
					return valid = false
				validQueue.push action
				console.log "validated"
				# action.branch.save action.attributes, syncToServer: true, validate: false
				rec @savingQueue.shift()
			if valid then @acceptChanges(validQueue) else @rejectChanges(validQueue.concat @savingQueue)

		rejectChanges: (validQueue, action = validQueue.shift()) ->
			do rec = (action = validQueue.shift()) =>
				return if not action?
				console.log "reject action", action, validQueue
				# action.branch.set action.previousAttributes
				Action.undo()
				rec validQueue, validQueue.shift()
			@savingQueue = []
			App.contentRegion.currentView.treeRegion.currentView.render()
		acceptChanges: (validQueue, action = validQueue.shift()) ->
			console.log "accept changes", validQueue
			# return if not action?
			# action.branch.save()
			# @acceptChanges validQueue, validQueue.shift()
