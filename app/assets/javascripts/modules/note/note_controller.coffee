@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	# Private --------------------------
	Note.startWithParent = false

	# Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes:
			"*filter": "filterItems"
	
	Note.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@notes = new App.Note.Collection()
		start: ->
			@showNoteInput @notes
			@showNoteCount @notes
			@showNoteView @notes
			App.listenTo @notes, "reset add remove", @toggleFooter, this
			@notes.fetch()
		showNoteInput: (notes) ->
			noteInput = new App.Note.Input(collection: notes)
			App.headerRegion.show noteInput
		showNoteCount: (notes) ->
			noteCount = new App.Note.Count(collection: notes)
			App.footerRegion.show noteCount
		showNoteView: (notes) ->
			noteView = new App.Note.CollectionView(collection: notes)
			App.mainRegion.show noteView
		toggleFooter: ->
			App.footerRegion.$el.toggle @.Note.Collection.length
		filterItems: (filter) ->
			# App.vent.trigger "note:filter", filter.trim() or ""
			
	# Initializers -------------------------
	App.Note.on "start", ->
		noteController = new Note.Controller()
		new Note.Router({controller: noteController})
		noteController.start()
)