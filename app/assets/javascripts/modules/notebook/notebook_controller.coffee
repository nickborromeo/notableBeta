@Notable.module "Notebook", (Notebook, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Notebook.startWithParent = false

	# Public -------------------------
	Notebook.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@forest = new App.Notebook.Forest()
			@activeTrunk = new App.Notebook.Trunk()
			@setEvents()
			@setGlobals()
		start: ->
			@forest.fetch success: =>
				Notebook.activeTrunk = @activeTrunk = @forest.first()
				Notebook.initializedTrunk.resolve()
		reset: ->
		setGlobals: ->
			Notebook.initializedTrunk = $.Deferred();
			Notebook.activeTrunk = @activeTrunk
			Notebook.forest = @forest
		setEvents: ->

	# Initializers -------------------------
	Notebook.addInitializer ->
		Notebook.notebookController = new Notebook.Controller()
		Notebook.notebookController.start()
		# new Notebook.Router controller: Notebook.controller
