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
				options: options
		triggerAction: (branch, attributes, options) ->
			@queueAction.apply(@, arguments)
			@processActionQueue()
			# @queueSaving attributes, branch

		processActionQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @actionQueue.shift()) =>
				return if not action?
				return if not @validate action.branch, action.attributes
				action.branch.save action.attributes, syncToServer: true
				# Push action to history
				rec @actionQueue.shift()
			@processingActions = false

		validate: (branch, attributes, options) ->
			return false if (branch.validate attributes)?
			true
