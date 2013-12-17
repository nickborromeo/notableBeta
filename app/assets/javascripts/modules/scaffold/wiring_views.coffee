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

		$(".alert").delay(7000).fadeOut(400);
		window.scrollTo(0,1)
)
