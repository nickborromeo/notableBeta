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
			buildTree = (allNotes) =>
				allNotes.each (note) =>
					@tree.add(note)
				@showContentView @tree
			# @allNotesByDepth.fetch success: buildTree
			@allNotesByDepth.fetch success:(allNotes) ->App.CrashPrevent.checkAndLoadLocal(buildTree, allNotes)

		showContentView: (tree) ->
			treeView = new App.Note.TreeView(collection: tree)
			App.contentRegion.currentView.treeRegion.show treeView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)