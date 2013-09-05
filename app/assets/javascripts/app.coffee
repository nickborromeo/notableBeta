@Notable = do (Backbone, Marionette) ->
	#  Create application root object and default regions
	App = new Marionette.Application

	App.addRegions
		headerRegion: "#header-region"
		mainRegion: "#main-region"
		sidebarRegion: "#sidebar-region"
		footerRegion: "#footer-region"

	# Run BEFORE/DURING/AFTER initializers
	App.on "initialize:before", (options) ->
		console.log options.currentUser.email

	App.addInitializer ->
		App.module("HeaderModule").start()
		App.module("FooterModule").start()

	App.on "initialize:after", ->
		if Backbone.history
			Backbone.history.start()
			# {pushState:true} 

	App

$ ->
	options = 
		currentUser: 
			username: "tester4"
			email: "tester4@notable.com"
			admin: true

	Notable.start(options)