@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes: {}
			# "*index": ""

	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@listOfNotes = new App.Note.Collection()
			@notes = new App.Note.Collection()
				
		start: ->
			@showNoteInput @notes
			@showNoteView @notes
			keepOnlyParents = (notes) =>
				keep = @keepOnlyParents.bind(this)
				notes.each keep
			@listOfNotes.fetch success: keepOnlyParents
		keepOnlyParents: (note) ->
			@notes.add(note) #if note.get('parent_id') is 'root'

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
