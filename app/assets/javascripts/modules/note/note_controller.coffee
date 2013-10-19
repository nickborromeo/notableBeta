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

		start: ->
			buildTree = (allNotes) =>
				allNotes.each (note) =>
					@tree.add(note)
				@showContentView @tree
			@allNotesByDepth.fetch success: buildTree

		showContentView: (tree) ->
			contentView = new App.Note.TreeView(collection: tree)
			App.contentRegion.show contentView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)
