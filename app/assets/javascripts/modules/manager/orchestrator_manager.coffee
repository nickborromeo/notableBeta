@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->
	
	class Action.Orchestrator

		constructor: ->
			@savingQueue = []
			@validationQueue = []
			@actionQueue = []
			@destroyQueue = []
			@destroyGuidQueue = []

		queueAction: (branch, attributes, options) ->
			# will have to play with the action manager
			@actionQueue.push
				branch: branch
				attributes: attributes
				previous_attributes: branch.attributes
				options: options
		queueDestroy: (branch) ->
			App.OfflineAccess.addDelete branch
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
				action.branch.set action.attributes
				App.OfflineAccess.addChange action.branch
				@validationQueue.push action
				# console.log "validationQueue", @validationQueue
				rec @actionQueue.shift()
			@processingActions = false
			@startSavingQueueTimeout()

		validate: (branch, attributes, options) ->
			if (val = branch.validation attributes)?
				# console.log val
				false
			else
				true

		startSavingQueueTimeout: ->
			@savingQueueTimeout = setTimeout @processSavingQueue.bind(@), 5000
		processSavingQueue: () ->
			valid = true
			savingQueue = []
			# console.log "Complete validation Queue"
			# _.each @validationQueue, (v) ->
			# 	console.log v.branch.get('guid'), v.branch.id, "Sent attributes", v.attributes, "branch attributes", v.branch.attributes
			@validationQueue = @trimValidQueue @validationQueue
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

		rejectChanges: (validQueue) ->
			@validationQueue = []
			App.Note.noteController.reset()
			App.OfflineAccess.clearCached()
			App.Notify.alert 'brokenTree', 'danger'
		processDestroy: ->
			# console.log "destroyQueue", @destroyQueue
			do rec = (branch = @destroyQueue.shift()) =>
				return if not branch?
				if branch.id?
					branch.destroy()				
				rec @destroyQueue.shift()
		acceptChanges: (validQueue) ->
			# console.log "accept changes", validQueue
			@processDestroy()
			# console.log "trimed changes", validQueue
			do rec = (branch = validQueue.shift()) ->
				return if not branch?
				branch.save()
				rec validQueue.shift()
			App.OfflineAccess.clearCached()
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
