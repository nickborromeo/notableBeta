@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Transporter

		constructor: () ->
			@storage = new Action.Storage
			@removed = []
			@backoffTimeoutID = -1
			@backoffCount = 0
			@MAX_BACKOFF = 140000 # 2 mins 20 secs

		testServerConnection: (forceBackoff = false) ->
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: =>
					@startSync()
				error: =>
					@notifyFailure forceBackoff
		notifyFailure: (forceBackoff) ->
			App.Notify.alert 'connectionLost', 'danger', {destructTime: 14000, count: @backoffCount}
			@backoff() if @isOnline() or forceBackoff

		# ------------ Back off methods ------------

		backoff: ->
			@backoffTimeoutID = setTimeout =>
	 			@testServerConnection true
			, @backoffTime()
			++@backoffCount
		backoffTime: ->
			time = Action.Helpers.fibonacci(@backoffCount) * 1000
			if time < @MAX_BACKOFF then time else @MAX_BACKOFF
		clearBackoff: (clearCount = false) ->
			clearTimeout @backoffTimeoutID
			@backoffTimeoutID = null
			@backoffCount = 0 if clearCount

		isOffline: ->
			@backoffTimeoutID?
		isOnline: ->
			!@isOffline()

		# -------------- Syncing with server ----------------
		# >> To remember : Data synced here might not have passed through validation
		#    since the Orchestrator sends data to localStorage before validating

		startSync: ->
			if @isOffline()
				@clearBackoff true
				if @storage.hasChangesToSync()
					App.Notify.alert 'syncing', 'warning'
					@syncActions()
			App.Note.syncingCompleted.resolve()
			App.Note.eventManager.trigger 'syncingDone'
		syncActions: ->
			deleteGuids = @collectDeletes()
			changeGuids = @collectChanges()
			_.each deleteGuids, (guid) => @syncDelete(guid)
			_.each changeGuids, (guid) => @syncChange(guid)
	
		collectDeletes: ->
			deleteGuids = Object.keys @storage.deletes
		collectChanges: ->
			changeGuids = Object.keys @storage.changes
		syncDelete: (guid) ->
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			options =	destroy: true, noLocalStorage: true
			@removed.push branch if branch?
			App.Note.allNotesByDepth.remove branch, options if branch?
		syncChange: (guid) ->
			return if @storage.isAlreadyInDeletes guid
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not branch?
 				branch = new App.Note.Branch()
				App.Note.allNotesByDepth.add branch
			attributes = @storage.getChanges(guid)
			options = noLocalStorage: true
			Backbone.Model.prototype.set.call(branch, attributes, options)

		addToStorage: (action) ->		
			if action.destroy
				@storage.addDelete action.branch
			else
				@storage.addChange action.branch
		processToServer: ->
			App.Note.allNotesByDepth.each (b) -> b.save()
			_.each @removed, (b) -> b.destroy() if b.id?
			@storage.clear()
			setTimeout -> # Purposely delayed so user can see 'syncing' notification
				App.Notify.alert 'synced', 'success'
			, 2000
