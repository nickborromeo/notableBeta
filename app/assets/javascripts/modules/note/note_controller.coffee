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
			@trunk = new App.Note.Trunk()

		start: ->
			buildTrunk = (allNotes) =>
				allNotes.each (note) =>
					@trunk.add(note)
				@showContentView @trunk
			@allNotesByDepth.fetch success: buildTrunk

		showContentView: (trunk) ->
			contentView = new App.Note.TreeView(collection: trunk)
			App.contentRegion.show contentView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)
