@Notable.module "Helpers", (Helpers, App, Backbone, Marionette, $, _) ->

	@ConnectionAPI =
		checkConnection: ->
			connection = $.Deferred()
			topModel = App.Notebook.forest.models[0]
			Backbone.sync "read", topModel,
				success: -> connection.resolve()
				error: -> connection.reject()
			connection.promise()

