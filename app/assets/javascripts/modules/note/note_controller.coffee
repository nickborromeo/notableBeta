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
			App.Note.activeTree = @tree
			App.Note.activeBranch = "root"
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
				App.Note.activeTree = App.Note.tree
				App.Note.activeBranch = "root"
			, 1000

		zoomIn: (guid) ->
			setTimeout =>
				console.log App.Note.tree, guid, App.Note.tree.findNote guid
				App.Note.activeTree = App.Note.tree.getCollection guid
				App.Note.activeBranch = App.Note.tree.findNote(guid)
				@showContentView App.Note.activeTree
				crownView = new App.Note.CrownView(model: App.Note.activeBranch)
				App.contentRegion.currentView.crownRegion.show crownView
			, 1000
	# Initializers -------------------------
	Note.addInitializer ->
		noteController = new Note.Controller()
		noteController.start()
		new Note.Router controller: noteController
)
