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
			App.User.activeUserInitialized.then =>
				@forest.fetch
					data: user_id: App.User.activeUser.id
					success: =>
						trunk = App.User.activeUser.getActiveNotebook()
						trunk = @forest.first() if not trunk?
						@showNotebookView(@forest)
						trunk.trigger 'select'
						Notebook.initializedTrunk.resolve()
		reset: ->
		setGlobals: ->
			Notebook.initializedTrunk = $.Deferred();
			Notebook.activeTrunk = @activeTrunk
			Notebook.forest = @forest
		setEvents: ->

		showNotebookView: (forest) ->
			App.sidebarRegion.currentView.notebookRegion.close()
			@forestView = new App.Notebook.ForestView(collection: forest)
			App.sidebarRegion.currentView.notebookRegion.show @forestView

	# Initializers -------------------------
	Notebook.addInitializer ->
		Notebook.notebookController = new Notebook.Controller()
		Notebook.notebookController.start()
		# new Notebook.Router controller: Notebook.controller
