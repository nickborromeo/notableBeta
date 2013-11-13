@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes: {}
			# "*index": ""

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@allNotesByDepth = new App.Note.Collection()
			@tree = new App.Note.Tree()
			App.Action.setTree @tree
			App.Action.setAllNotesByDepth @allNotesByDepth
			App.CrashPrevent.setTree @tree
			App.CrashPrevent.setAllNotesByDepth @allNotesByDepth

		start: ->
			@allNotesByDepth.fetch success: => App.CrashPrevent.checkAndLoadLocal (_.bind @buildTree, @)

		buildTree: ->
			@allNotesByDepth.sort()
			@allNotesByDepth.each (note) =>
				@tree.add(note)
			@showContentView(@tree)

		showContentView: (tree) =>
			treeView = new App.Note.TreeView(collection: tree)
			App.contentRegion.currentView.treeRegion.show treeView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)