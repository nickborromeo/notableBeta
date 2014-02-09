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
			return false

		onMainPage = $("#content-region").length > 0
		if not Modernizr.touch and onMainPage
			$(".container").idle (->
				App.Helper.eventManager.trigger "hideChrome"
			), ->
				App.Helper.eventManager.trigger "showChrome"

)