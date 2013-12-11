@Notable.module "Notebook", (Notebook, App, Backbone, Marionette, $, _) ->


	Notebook.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@forest = new App.Notebook.Forest()
			@activeTrunk = new App.Notebook.Trunk()
			@setGlobals()
			@setEvents()
		start: ->
			@forest.fetch success: =>
				console.log @forest
				@activeTrunk = @forest.first()
				Notebook.initializedTrunk.resolve()
		reset: ->
		setGlobals: ->
			Notebook.initializedTrunk = $.Deferred();
			Notebook.activeTrunk = @activeTrunk
			Notebook.forest = @forest
		setEvents: ->

	# Initializers -------------------------
	Notebook.addInitializer ->
		Notebook.controller = new Notebook.Controller()
		Notebook.controller.start()
		# new Notebook.Router controller: Notebook.controller
