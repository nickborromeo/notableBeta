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
			@notes = new App.Note.Tree()

		start: ->
			buildTree = (notes) =>
				_.each notes.models, (note) =>
					@notes.add(note)
				@showNoteView @notes
			@allNotesByDepth.fetch success: buildTree

		showNoteView: (notes) ->
			noteView = new App.Note.CollectionView(collection: notes)
			App.mainRegion.show noteView

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)
