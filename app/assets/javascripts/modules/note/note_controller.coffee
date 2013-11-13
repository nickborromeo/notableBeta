@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.eventManager = _.extend {}, Backbone.Events

	Note.Router = Marionette.AppRouter.extend
		appRoutes:
			"zoom/:guid": "zoomIn"
			"*index": "clearZoom"

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			Note.eventManager.on "clearZoom", @clearZoom, @
			@allNotesByDepth = new App.Note.Collection()
			@tree = new App.Note.Tree()

			Note.initializedTree = $.Deferred();
			Note.tree = @tree
			Note.activeTree = @tree
			Note.activeBranch = "root"

			App.Action.setTree @tree
			App.Action.setAllNotesByDepth @allNotesByDepth

		start: ->
			buildTree = (allNotes) =>
				allNotes.each (note) =>
					@tree.add(note)
				@showContentView @tree
				App.Note.initializedTree.resolve()
			@allNotesByDepth.fetch success: buildTree

		showContentView: (tree) ->
			if @treeView?
				@treeView.collection = tree
				@treeView.render()
			else
				@treeView = new App.Note.TreeView(collection: tree)
				App.contentRegion.currentView.treeRegion.show @treeView

		clearZoom: ->
			App.Note.initializedTree.then =>
				console.log "clear"
				@showContentView App.Note.tree
				App.Note.activeTree = App.Note.tree
				App.Note.activeBranch = "root"

		zoomIn: (guid) ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree.getCollection guid
				App.Note.activeBranch = App.Note.tree.findNote(guid)
				@showContentView App.Note.activeTree
				crownView = new App.Note.CrownView(model: App.Note.activeBranch)
				App.contentRegion.currentView.crownRegion.show crownView
	# Initializers -------------------------
	Note.addInitializer ->
		noteController = new Note.Controller()
		noteController.start()
		new Note.Router controller: noteController
)
