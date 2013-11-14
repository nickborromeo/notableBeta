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
		showCrownView: ->
			if @crownView?
				@crownView.model = App.Note.activeBranch
				@crownView.render()
			else
				@crownView = new App.Note.CrownView(model: App.Note.activeBranch)
				App.contentRegion.currentView.crownRegion.show @crownView
		clearCrownView: ->
			if @crownView?
				@crownView.close()
				delete @crownView
			App.Note.activeBranch = "root"
		showBreadcrumbView: ->
			if @breadcrumbView?
				@breadcrumbView.collection = new Note.Breadcrumbs null, Note.activeBranch
				@breadcrumbView.render()
			else
				@breadcrumbView = new App.Note.BreadcrumbsView(collection: new Note.Breadcrumbs null, Note.activeBranch)
				App.contentRegion.currentView.breadcrumbRegion.show @breadcrumbView
		clearBreadcrumbView: ->
			if @breadcrumbView?
				@breadcrumbView.close()
				delete @breadcrumbView
			App.Note.activeBranch = "root"


		clearZoom: ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree
				@clearCrownView()
				@showContentView App.Note.tree
				@clearBreadcrumbView()
				if Note.tree.first()?
					Note.eventManager.trigger "setCursor:#{Note.tree.first().get('guid')}"

		zoomIn: (guid) ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree.getCollection guid
				App.Note.activeBranch = App.Note.tree.findNote(guid)
				@showCrownView()
				@showContentView App.Note.activeTree
				@showBreadcrumbView()
				if Note.activeTree.first()?
					Note.eventManager.trigger "setCursor:#{Note.activeTree.first().get('guid')}"

	# Initializers -------------------------
	Note.addInitializer ->
		noteController = new Note.Controller()
		noteController.start()
		new Note.Router controller: noteController
)
