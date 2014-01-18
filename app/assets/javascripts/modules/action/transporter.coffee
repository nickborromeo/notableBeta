@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Transporter

		constructor: () ->
			@backOffTimeoutID = null
			@backOffInterval = 0

		# ------------ back off methods ------------

		startBackOff: (count = @backOffInterval, clearFirst = false) ->
			if clearFirst then @clearBackOff()
			unless @isOffline()
				time = Action.Helpers.fibonacci(count) * 1000
				@backOffTimeoutID = setTimeout =>
					@startSync ++count
				, time

		# Keep in mind condition is broken
		notifyFailureAndBackOff: (count) ->
			App.Notify.alert 'connectionLost', 'danger', {selfDestruct: false}
			if Action.Helpers.fibonacci(count) < 140000 then @startBackOff count, true
			else @startBackOff count, true

		clearBackOff: ->
			clearTimeout @backOffTimeoutID
			@backOffTimeoutID = null

		isOffline: ->
			@backOffTimeoutID?
		isOnline: ->
			!@isOffline()

		informConnectionSuccess: ->
			if @isOffline()
				@clearBackOff()
				@startSync()

		# ------------ Syncing with server: this is the order in which they are called ----------

		# downloads all notes, this is not reflected in DOM
		# PROBLEM WITH THE FUNCTION
		# Have to be able to be called without knowing the actual count
		startSync: (time = @backOffInterval, callback) ->
			App.Notify.alert 'synced', 'save'
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: => @deleteAndSave Object.keys(Action.storage.deletes), time, callback
				error: => @notifyFailureAndBackOff(time)

		# deletes all notes that were deleted to fix server ID references
		deleteAndSave: (notesToDelete, time, callback) ->
			unless notesToDelete.length > 0
				return @startAllNoteSync time, callback
			noteReference = App.Note.allNotesByDepth.findWhere {guid: notesToDelete.shift()}
			options =
				success: (note) =>
					@clearBackOff()
					@deleteAndSave notesToDelete, time, callback
				error: => @notifyFailureAndBackOff(time)
			options.destroy = true
			options.noLocalStorage = true
			if noteReference? then noteReference.destroy options # App.Action.orchestrator.trigger noteReference, null, options
			else options.success()

		# starts to sync the actual note data, ranks, depth, parent IDs, etc
		startAllNoteSync: (time, callback) ->
			changeHashGUIDs = Object.keys Action.storage.changes
			@fullSyncNoAsync changeHashGUIDs, time, callback

		# syncing the actual note data
		fullSyncNoAsync: (changeHashGUIDs, time, callback) ->
			unless changeHashGUIDs.length > 0
				if Action.storage.hasChangesToSync()
					App.Notify.alertOnly 'syncing', 'warning'
				Action.storage.clearCached()
				if callback? then return callback() else return

			options =
				success: =>
					@clearBackOff()
					@fullSyncNoAsync changeHashGUIDs, time, callback
				error: => @notifyFailureAndBackOff(time)

			guid = changeHashGUIDs.pop()
			@loadAndSave guid, Action.storage.getChanges(guid), options

		loadAndSave: (guid, attributes, options) ->
			noteReference = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not noteReference? and not Action.storage.isAlreadyInDeletes guid
				noteReference = new App.Note.Branch()
				App.Note.allNotesByDepth.add noteReference
			if noteReference?
				Backbone.Model.prototype.save.call(noteReference,attributes,options)
				options.noLocalStorage = true
				# App.Action.orchestrator.triggerAction noteReference, attributes, options
			else
				options.success()

		checkAndLoadLocal: (buildTreeCallBack) ->
			Action.storage.loadCached()
			@startSync(null, buildTreeCallBack)
			if Action.storage.hasChangesToSync()
				App.Note.initializedTree.then -> App.Notify.alert 'synced', 'success'
