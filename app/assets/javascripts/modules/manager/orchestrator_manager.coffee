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
				# if action.options.type is 'save'
				return if not @validate action.branch, action.attributes
				# action.branch.save action.attributes, syncToServer: true, validate: false
				action.args = [action.attributes, syncToServer: true, validate: false]
				console.log "set", action.branch.attributes, action.attributes
				action.branch.set action.attributes
			 	# else if action.options.type is 'destroy'
				# 	action.branch.destroy syncToServer: true, validate: false
				# 	action.args = [syncToServer: true, validate: false]
				# Push action to history
				@savingQueue.push action
				rec @actionQueue.shift()
			@processingActions = false

		validate: (branch, attributes, options) ->
			if (val = branch.validate attributes)?
				console.log val
				false
			else
				true
