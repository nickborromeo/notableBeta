@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Transporter

		constructor: () ->
			@backOffTimeoutID = null
			@backOffInterval = 0

		# ------------ Back off methods ------------

		startBackOff: (count = @backOffInterval, clearFirst = false) ->
			if clearFirst then @clearBackOff()
			unless @isOffline()
				time = Action.Helpers.fibonacci(count) * 1000
				@backOffTimeoutID = setTimeout =>
					@syncActions ++count
				, time

		# >> Keep in mind condition is broken because ...
		failureBackoff: (count) ->
			App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
			if Action.Helpers.fibonacci(count) < 140000 then @startBackOff count, true
			else @startBackOff count, true

		clearBackOff: ->
			clearTimeout @backOffTimeoutID
			@backOffTimeoutID = null

		isOffline: ->
			@backOffTimeoutID?

		informConnectionSuccess: ->
			if @isOffline()
				@clearBackOff()
				@syncActions()

		# -------------- Syncing with server ----------------

		# >> Issue: Have to be able to be called without knowing the actual count
		# >> Are we trying to fetch all notes or just trying to see if there
		#    is a connetion to the server?
		# >> We don't seem to do anything with the notes once we get them.
		syncActions: (time = @backOffInterval, callback) ->
			App.Notify.alert 'syncing', 'save'
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: => @collectDeleteGuids(time, callback)
				error: => @failureBackoff(time)
		###
			testServerConnection().then ->
				return collectDeleteGuids()
			.then ->
			  return syncDeletes()
			.then ->
			  return collectChangeGuids()
			.then ->
			  return syncChanges()
			.catch (error) ->
			  console.log #{error.message}
			  return failureBackoff()
		###

		# starts to delete removed notes
		collectDeleteGuids: (time, callback) ->
			deleteGuids = Object.keys(Action.storage.deletes)
			@syncDeletes deleteGuids, time, callback

		# deletes all notes that were deleted to fix server ID references
		syncDeletes: (deleteGuids, time, callback) ->
			unless deleteGuids.length > 0
				return @collectChangeGuids time, callback
			noteToDelete = App.Note.allNotesByDepth.findWhere {guid: deleteGuids.shift()}
			options =
				success: (note) =>
					@clearBackOff()
					App.Notify.alert 'synced', 'save'
					@syncDeletes deleteGuids, time, callback
				error: => @failureBackoff(time)
			options.destroy = true
			options.noLocalStorage = true
			if noteToDelete? then noteToDelete.destroy options # App.Action.orchestrator.trigger noteToDelete, null, options
			else options.success()

		# starts to sync the actual note data, ranks, depth, parent IDs, etc
		collectChangeGuids: (time, callback) ->
			changeGuids = Object.keys Action.storage.changes
			@fullSyncNoAsync changeGuids, time, callback

		# syncing the actual note data
		# >> fullSyncNoAsync looks like the parallel to syncDeletes, but
		#    loadAndSave is where changes are actually synced
		# >> wtf does fullSyncNoAsync even mean? it's like the worst of
		#    both worlds: super long name, but not at all descriptive of
		#    what is happening in the function
		fullSyncNoAsync: (changeGuids, time, callback) ->
			unless changeGuids.length > 0
				if Action.storage.hasChangesToSync()
					App.Notify.alertOnly 'syncing', 'warning'
				Action.storage.clearCached()
				if callback? then return callback() else return
			options =
				success: =>
					@clearBackOff()
					@fullSyncNoAsync changeGuids, time, callback
				error: => @failureBackoff(time)
			guid = changeGuids.pop()
			@loadAndSave guid, Action.storage.getChanges(guid), options

		# which one should be called syncChanges?
		loadAndSave: (guid, attributes, options) ->
			noteToSave = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not noteToSave? and not Action.storage.isAlreadyInDeletes guid
				noteToSave = new App.Note.Branch()
				App.Note.allNotesByDepth.add noteToSave
			if noteToSave?
				Backbone.Model.prototype.save.call(noteToSave,attributes,options)
				options.noLocalStorage = true
				# App.Action.orchestrator.triggerAction noteToSave, attributes, options
			else
				options.success()

		checkAndLoadLocal: (buildTreeCallBack) ->
			Action.storage.loadCached()
			@syncActions(null, buildTreeCallBack)
			if Action.storage.hasChangesToSync()
				App.Note.initializedTree.then -> App.Notify.alert 'synced', 'success'
