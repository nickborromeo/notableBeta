@Notable.module("Wiring", (Wiring, App, Backbone, Marionette, $, _) ->
	Wiring.startWithParent = false

	App.Wiring.on "start", ->
		$(".alert").delay(7000).fadeOut(1400)

		$('.sidebar-toggle').sidr
			name: 'sidebar-center'
			source: '#sidebar-center'
		$('.sidr-toggle-left').sidr
			name: 'sidebar-center'
			source: '#sidebar-center'
		# $('.sidr-toggle-right').sidr
		# 	name: 'settings-sidebar'
		# 	source: '#settings-sidebar'
)
