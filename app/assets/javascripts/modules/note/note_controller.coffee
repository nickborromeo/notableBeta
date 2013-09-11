@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
  # Private --------------------------
  # Note.startWithParent = false

  # Public -------------------------
	Note.Router = Marionette.AppRouter.extend
		appRoutes:
			"*filter": "filterItems"
	Note.Controller = ->
		@notes = new App.Note.Collection()

  _.extend Note.Controller::,
	  start: ->
	    @showHeader @notes
	    @showFooter @notes
	    @showNotes @notes
    	App.bindTo @notes, "reset add remove", @toggleFooter, this
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
    	App.footerRegion.$el.toggle @notes.length
	  filterItems: (filter) ->
	    App.vent.trigger "note:filter", filter.trim() or ""

  # Initializers -------------------------
  Note.addInitializer ->
    controller = new Note.Controller()
    new Note.Router(controller: controller)
    controller.start()
)