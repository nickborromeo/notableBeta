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
			Note.allNotesByDepth = @allNotesByDepth
			App.Action.orchestrator = new App.Action.Orchestrator()
		start: ->
			App.OfflineAccess.checkAndLoadLocal (_.bind @buildTree, @)
		buildTree: ->
			@allNotesByDepth.sort()
			@allNotesByDepth.validateTree()
			@allNotesByDepth.each (note) =>
				@tree.add(note)
			@showContentView(@tree)
			App.Note.initializedTree.resolve()

		showContentView: (tree) ->
			App.contentRegion.currentView.treeRegion.close()
			@treeView = new App.Note.TreeView(collection: tree)
			App.contentRegion.currentView.treeRegion.show @treeView
		showCrownView: ->
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
		# showNoteBookTitle: ->
		# 	if @showTitleView?
		# 		@breadcrumbView.collection = new Note.Breadcrumbs null, Note.activeBranch
		# 		@breadcrumbView.render()
		# 	else
		# 		@breadcrumbView = new App.Note.BreadcrumbsView(collection: new Note.Breadcrumbs null, Note.activeBranch)
		# 		App.contentRegion.currentView.breadcrumbRegion.show @breadcrumbView
		showNotebookTitleView: ->
			if @notebookTitleView?
				@notebookTitleView.render()
			else
				@notebookTitleView = new App.Note.NotebookTitleView()
			App.contentRegion.currentView.breadcrumbRegion.show @notebookTitleView
			App.Note.activeBranch = "root"


		clearZoom: ->
			App.Note.initializedTree.then =>
				App.Note.activeTree = App.Note.tree
				@clearCrownView()
				@showContentView App.Note.tree
				@showNotebookTitleView()
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
