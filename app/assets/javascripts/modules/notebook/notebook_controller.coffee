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
						Notebook.activeTrunk = trunk
						@showNotebookView(@forest)
						trunk.trigger 'select'
						Notebook.initializedTrunk.resolve()
						@emptyNotebookTrash()
		reset: ->
		setGlobals: ->
			Notebook.initializedTrunk = $.Deferred();
			Notebook.activeTrunk = @activeTrunk
			Notebook.forest = @forest
			@config = Notebook.config = zoomingItem: "notebookZooms"
			@config.zooms = JSON.parse(window.localStorage.getItem(@config.zoomingItem)) ? {}
		setEvents: ->
			App.Note.eventManager.on "undoNotebookDeletion", @undoNotebookDeletion, @
			App.Note.eventManager.on "notebook:zoomIn", @zoomIn, @
			App.Note.eventManager.on "notebook:clearZoom", @clearZoom, @

		showNotebookView: (forest) ->
			App.sidebarRegion.currentView.notebookRegion.close()
			@forestView = new App.Notebook.ForestView(collection: forest)
			App.sidebarRegion.currentView.notebookRegion.show @forestView

		undoNotebookDeletion: ->
			$.get "notebooks/undoDelete/#{Notebook.config.lastNotebookDeleted}.json", (notebook) =>
				@forest.add notebook
		emptyNotebookTrash: ->
			$.get "notebooks/emptyTrash/#{App.User.activeUser.id}.json"

		zoomIn: (branch_id) ->
			@config.zooms[Notebook.activeTrunk.id] = branch_id
			window.localStorage.setItem @config.zoomingItem, JSON.stringify(@config.zooms)
		clearZoom: ->
			delete @config.zooms[Notebook.activeTrunk.id]
			window.localStorage.setItem @config.zoomingItem, JSON.stringify(@config.zooms)

	# Initializers -------------------------
	Notebook.addInitializer ->
		Notebook.notebookController = new Notebook.Controller()
		Notebook.notebookController.start()
		# new Notebook.Router controller: Notebook.controller
