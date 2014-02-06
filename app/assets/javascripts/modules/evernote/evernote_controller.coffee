@Notable.module "Evernote", (Evernote, App, Backbone, Marionette, $, _) ->

	Evernote.Controller = Marionette.Controller.extend
		initialize: (options) ->
			@initEvernote()

		evernoteInitFunctions:
			sync_flow: ->
				$('.sync-action').on 'click', (e) ->
					e.preventDefault()
					App.Action.orchestrator.triggerSaving ->
						App.Note.noteController.showEvernoteView()
			connect_flow: ->
				$('.connect-evernote-action').on 'click', (e) ->
					e.preventDefault()
					App.Action.orchestrator.triggerSaving ->
						window.location.href = 'connect'

		initEvernote: ->
			_(@evernoteInitFunctions).each (fn) ->
				fn()			

	# Initializers -------------------------
	Evernote.addInitializer ->
		Evernote.controller = new Evernote.Controller()
