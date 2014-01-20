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
					@testServerConnection ++count
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

		# -------------- Syncing with server ----------------

		# >> Issue: Have to be able to be called without knowing the actual count
		# syncActions: (time = @backOffInterval, callback) ->
		# 	App.Notify.alert 'syncing', 'save'
		# 	App.Note.allNotesByDepth.fetch
		# 		success: => @collectDeletes(time, callback)
		# 		error: => @failureBackoff(time)
		# >> To remember : Data synced here might not have passed through validation
		#    since the Orchestrator sends data to localStorage before validating
		# >> needs to be more robust because connection can be lost while syncing,
		#    which could leave the tree in a broken state

		testServerConnection: (count) ->
			App.Note.allNotesByDepth.fetch
				data: notebook_id: App.Notebook.activeTrunk.id
				success: =>
					@startSync()
				error: =>
					@failureBackoff(count)
		startSync: ->
			if @isOffline()
				@clearBackOff()
				App.Notify.alert 'syncing', 'warning'
				@syncActions()

		syncActions: ->
			deleteGuids = @collectDeletes()
			changeGuids = @collectChanges()
			_.each deleteGuids, (guid) => @syncDelete(guid)
			_.each changeGuids, (guid) => @syncChange(guid)
			Action.storage.clearCached()
			callback() if callback?

		collectDeletes: ->
			deleteGuids = Object.keys Action.storage.deletes
		collectChanges: ->
			changeGuids = Object.keys Action.storage.changes
		syncDelete: (guid) ->
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			options =	destroy: true, noLocalStorage: true
			branch.destroy options if branch?
		syncChange: (guid) ->
			return if Action.storage.isAlreadyInDeletes guid
			branch = App.Note.allNotesByDepth.findWhere {guid: guid}
			if not branch?
 				branch = new App.Note.Branch()
				App.Note.allNotesByDepth.add branch
			options = noLocalStorage: true
			Backbone.Model.prototype.save.call(branch, attributes, options)

		checkAndLoadLocal: (buildTreeCallBack) ->
			Action.storage.loadCached()
			@syncActions(null, buildTreeCallBack)
			if Action.storage.hasChangesToSync()
				App.Note.initializedTree.then -> App.Notify.alert 'synced', 'success'
