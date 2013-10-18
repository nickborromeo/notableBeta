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
<<<<<<< HEAD
			@trunk = new App.Note.Trunk()

		start: ->
			buildTrunk = (allNotes) =>
				allNotes.each (note) =>
					@trunk.add(note)
				@showNoteView @trunk
			@allNotesByDepth.fetch success: buildTrunk

		showNoteView: (trunk) ->
			noteView = new App.Note.CollectionView(collection: trunk)
			App.contentRegion.show noteView
=======
			@notes = new App.Note.Tree()

		start: ->
			# @showNoteInput @notes
			buildTree = (notes) =>
				_.each notes.models, (note) =>
					@notes.add(note)
				@showNoteView @notes
			@allNotesByDepth.fetch success: buildTree

		# showNoteInput: (notes) ->
		# 	noteInput = new App.Note.Input(collection: notes)
		# 	App.headerRegion.show noteInput
		showNoteView: (notes) ->
			noteView = new App.Note.CollectionView(collection: notes)
			App.mainRegion.show noteView
			# if !@shown?
			# 	@shown = true
			# 	noteView = new App.Note.TreeView(collection: notes)
			# 	App.mainRegion.show noteView
>>>>>>> 8f25073a52dcb6c8ba243c6164cf1d816c559aba

	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)
