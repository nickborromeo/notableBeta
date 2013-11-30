@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->
	
	class Action.Orchestrator

		constructor: ->
			@savingQueue = []
			@validationQueue = []
			@actionQueue = []
			@destroyQueue = []
			@destroyGuidQueue = []

		queueAction: (branch, attributes, options) ->
			# will probably have to play with the action manager
			@actionQueue.push
				branch: branch
				attributes: attributes
				previous_attributes: branch.attributes
				options: options
		queueDestroy: (branch) ->
			@destroyQueue.push branch
		triggerAction: (branch, attributes, options = {}) ->
			clearTimeout @savingQueueTimeout
			if options.destroy
				@queueDestroy.apply @, arguments
				@startSavingQueueTimeout()
			else
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
				@validationQueue.push action
				console.log "validationQueue", @validationQueue
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
			@savingQueueTimeout = setTimeout @processSavingQueue.bind(@), 1000
		processSavingQueue: () ->
			valid = true
			savingQueue = []
			@validationQueue = @trimValidQueue @validationQueue
			console.log "validation queue", @validationQueue
			do rec = (branch = @validationQueue.shift()) =>
				return if not branch? or not valid
				console.log "processing savingQueue", branch
				if not @validate branch, branch.attributes
					return valid = false
				savingQueue.push branch
				console.log branch.get('guid'), "validated"
				# action.branch.save action.attributes, syncToServer: true, validate: false
				rec @validationQueue.shift()
			if valid then @acceptChanges(savingQueue) else @rejectChanges(savingQueue)

		rejectChanges: (validQueue) ->
			throw "The set of changes break the tree"
			# undoCount = validQueue.length
			# queue = validQueue.concat @savingQueue
			# do rec = (action = queue.shift()) =>
			# 	return if not action?
			# 	console.log "reject action", action, queue
				# 	# action.branch.set action.previousAttributes
			# 	Action.undo() if (undoCount-- >= 0)
			# 	setTimeout (-> rec queue.shift()), 100
			# @savingQueue = []
			# App.contentRegion.currentView.treeRegion.currentView.render()
		processDestroy: ->
			console.log "destroyQueue", @destroyQueue
			do rec = (branch = @destroyQueue.shift()) =>
				return if not branch?
				if branch.id?
					branch.destroy()				
				rec @destroyQueue.shift()
		acceptChanges: (validQueue) ->
			console.log "accept changes", validQueue
			@processDestroy()
			console.log "trimed changes", validQueue
			do rec = (branch = validQueue.shift()) ->
				return if not branch?
				branch.save()
				rec validQueue.shift()
			# return if not action?
			# action.branch.save()
			# @acceptChanges validQueue, validQueue.shift()
		# trimValidQueue: (validQueue) ->
		# 	_.filter validQueue, (obj) ->
		# 		keep = true;
		# 		_.each obj.attributes, (val, key) ->
		# 			keep = false if obj.branch.get(key) isnt val
		# 		keep
		getDestroyGuids: ->
			guids = []
			_.each @destroyQueue, (toDestroy) ->
				guids.push toDestroy.guid
		trimValidQueue: (validQueue) ->
			guids = []
			queue = []
			_.each validQueue, (obj) =>
				if obj.branch.get('guid') not in guids and obj.branch not in @destroyQueue
					guids.push obj.branch.get('guid')
					queue.push obj.branch
			queue
