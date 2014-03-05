@Notable.module "Evernote", (Evernote, App, Backbone, Marionette, $, _) ->
	Evernote.startWithParent = false

	Evernote.Controller = Marionette.Controller.extend
		initialize: ->

		evernoteEventListeners:
			sync_flow: ->
				$('.sync-with-evernote').on 'click', (e) ->
					e.preventDefault()
					App.Action.orchestrator.triggerSaving ->
						App.Note.noteController.showEvernoteView()
			connect_flow: ->
				$('.connect-to-evernote').on 'click', (e) ->
					e.preventDefault()
					App.Action.orchestrator.triggerSaving ->
						window.location.href = 'connect'

		start: ->
			_(@evernoteEventListeners).each (listener) ->
				listener()

	# Initializers -------------------------
	Evernote.addInitializer ->
		Evernote.evernoteController = new Evernote.Controller()
		Evernote.evernoteController.start()
