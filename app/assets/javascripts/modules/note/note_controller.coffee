@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes:
			"": "clearZoom"
			"zoom/:guid": "zoomIn"
			# "*index": ""

	Note.eventManager = _.extend {}, Backbone.Events

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@allNotesByDepth = new App.Note.Collection()
			@tree = new App.Note.Tree()
			App.Note.tree = @tree
			App.Action.setTree @tree
			App.Action.setAllNotesByDepth @allNotesByDepth

		start: ->
			buildTree = (allNotes) =>
				allNotes.each (note) =>
					@tree.add(note)
				@showContentView @tree
			@allNotesByDepth.fetch success: buildTree

		showContentView: (tree) ->
			treeView = new App.Note.TreeView(collection: tree)
			App.contentRegion.currentView.treeRegion.show treeView

		clearZoom: ->
			console.log "clearZoom"
			setTimeout =>
				@showContentView App.Note.tree
			, 1000
			
		zoomIn: (guid) ->
				console.log App.Note.tree, guid, App.Note.tree.findNote guid
				@showContentView App.Note.tree.getCollection guid

	# Initializers -------------------------
	Note.addInitializer ->
		noteController = new Note.Controller()
		noteController.start()
		new Note.Router controller: noteController
)
