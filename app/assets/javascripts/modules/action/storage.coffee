@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Storage

		constructor: () ->
			@changesKey = 'unsyncedChanges'
			@deletesKey = 'unsyncedDeletes'
			@syncChangesKey = 'syncingChanges'
			@syncDeletesKey = 'syncingDeletes'
			@load()

		addChange: (branch) ->
			attributes = branch.getAllAtributes()
			@changes[attributes.guid] = attributes
			window.localStorage.setItem @changesKey, JSON.stringify(@changes)
		addDelete: (branch, toDelete = true)->
			guid = branch.get('guid')
			if toDelete then @deletes[guid] = toDelete
			else delete @deletes[guid]
			window.localStorage.setItem @deletesKey, JSON.stringify(@deletes)

		collectDeletes: ->
			deleteGuids = Object.keys @syncDeletes
		collectChanges: ->
			changeGuids = Object.keys @syncChanges


		clear: (clearSyncing = true) ->
			@changes = {}
			@deletes = {}
			window.localStorage.setItem @changesKey, JSON.stringify(@changes)
			window.localStorage.setItem @deletesKey, JSON.stringify(@deletes)
			@clearSyncing() if clearSyncing

		clearSyncing: ->
			@syncChanges = {}
			@syncDeletes = {}
			window.localStorage.setItem @syncChangesKey, JSON.stringify(@syncChanges)
			window.localStorage.setItem @syncDeletesKey, JSON.stringify(@syncDeletes)

		load: ->
			@changes = JSON.parse(window.localStorage.getItem @changesKey) ? {}
			@deletes = JSON.parse(window.localStorage.getItem @deletesKey) ? {}
			@syncChanges = JSON.parse(window.localStorage.getItem @syncChangesKey) ? {}
			@syncDeletes = JSON.parse(window.localStorage.getItem @syncDeletesKey) ? {}

		getChanges: (guid) ->
			@syncChanges[guid]
		isAlreadyInDeletes: (guid) ->
			@syncDeletes[guid]?
		isAlreadyInChanges: (guid) ->
			@changes[guid]?

		swapToSync: ->
			@syncChanges = @changes
			@syncDeletes = @deletes
			window.localStorage.setItem @syncChangesKey, JSON.stringify(@syncChanges)
			window.localStorage.setItem @syncDeletesKey, JSON.stringify(@syncDeletes)
			@clear(false)

		hasChangesToSync: ->
			_.any(@deletes) or _.any(@changes) or
			_.any(@syncDeletes) or _.any(@syncChanges)
