@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes: {}
			# "*index": ""

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@notes = new App.Note.Collection()
		start: ->
			@showNoteInput @notes
			@showNoteView @notes
			@notes.fetch()
		showNoteInput: (notes) ->
			noteInput = new App.Note.Input(collection: notes)
			App.headerRegion.show noteInput
		showNoteView: (notes) ->
			noteView = new App.Note.CollectionView(collection: notes)
			App.mainRegion.show noteView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)
