@Notable.module "Action", (Action, App, Backbone, Marionette, $, _) ->

	class Action.Storage

		constructor: () ->
			@changesKey = 'unsyncedChanges'
			@deletesKey = 'unsyncedDeletes'
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

		clear: ->
			@changes = {}
			@deletes = {}
			window.localStorage.setItem @changesKey, JSON.stringify(@changes)
			window.localStorage.setItem @deletesKey, JSON.stringify(@deletes)
		load: ->
			@changes = JSON.parse(window.localStorage.getItem @changesKey) ? {}
			@deletes = JSON.parse(window.localStorage.getItem @deletesKey) ? {}

		getChanges: (guid) ->
			@changes[guid]
		isAlreadyInDeletes: (guid) ->
			@deletes[guid]?
		isAlreadyInChanges: (guid) ->
			@changes[guid]?

		hasChangesToSync: ->
			_.any(@deletes) or _.any(@changes)
