@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->
	
	class Action.Orchestrator

		constructor: ->
			@savingQueue = []
			@actionQueue = []

		queueAction: (branch, options) ->
			# will probably have to play with the action manager
			@actionQueue.push
				branch: branch
				attributes: branch.attributes
				previous_attributes: branch._previousAttributes
				options: branch
		triggerAction: (branch, options) ->
			@queueAction.apply(@, arguments)
			@processActionQueue()
			# @queueSaving attributes, branch

		processActionQueue: ->
			return if @processingActions
			@processingActions = true
			do rec = (action = @actionQueue.shift()) =>
				return if not action?
				return if @validate action.branch, action.attributes
				action.branch.save action.attributes syncToServer: true
				# Push action to history
				rec @actionQueue.shift()
			@processingActions = false

		validate: (branch, attributes, options) ->
			return false if branch.validate attributes?
			true
