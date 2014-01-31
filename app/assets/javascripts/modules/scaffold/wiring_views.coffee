@Notable.module("Wiring", (Wiring, App, Backbone, Marionette, $, _) ->
	Wiring.startWithParent = false

	App.Wiring.on "start", ->
		$('.sidebar-toggle').sidr
			name: 'left-sidr-center'
			source: '#left-sidr-center'
			side: 'left'
		$('.sidr-toggle-left').sidr
			name: 'left-sidr-center'
			source: '#left-sidr-center'
			side: 'left'
		$('.sidr-toggle-right').sidr
			name: 'right-sidr-center'
			source: '#right-sidr-center'
			side: 'right'

		window.scrollTo(0,1)
		$(document).bind 'keydown', 'ctrl+s meta+s', (e) ->
			e.preventDefault()
			App.Action.orchestrator.triggerSaving()
			false

		$(document).ready ->
			Wiring.Evernote.sync_flow()

	Wiring.Evernote =
		sync_flow: ->
			$('.sync_now_test').on 'click', ->
				App.Action.orchestrator.triggerSaving()
				$.get "/sync", (data) ->
					App.Note.noteController.reset ->
						App.Notify.alert 'evernoteSync', 'success' # maybe a bit short?				
				
)
