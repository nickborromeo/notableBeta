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

		$(".container").idle (->
			App.Helper.eventManager.trigger "hideChrome"
		), ->
			App.Helper.eventManager.trigger "showChrome"

		# chromeHidden = false; idleTimer = false
		# $(document).mousemove ->
		# 	if idleTimer
		# 		clearTimeout idleTimer
		# 		idleTimer = 0
		# 	if chromeHidden
		# 		$(".container").mouseover ->
		# 			App.Helper.eventManager.trigger "showChrome"
		# 			chromeHidden = false
		# 	idleTimer = setTimeout ->
		# 		App.Helper.eventManager.trigger "hideChrome"
		# 		chromeHidden = true
		# 		return false
		# 	, 3000
		# 	return false
)
