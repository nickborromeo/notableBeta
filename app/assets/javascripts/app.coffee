@Notable = do (Backbone, Marionette) ->
	# Create application root object and default regions
	App = new Marionette.Application

	App.addRegions
		headerRegion: "#header-region"
		mainRegion: "#main-region"
		sidebarRegion: "#sidebar-region"
		footerRegion: "#footer-region"

	# Run BEFORE/DURING/AFTER initializers
	App.on "initialize:before", ->

	App.addInitializer ->
		App.module("Scaffold").start()
		App.module("Note").start()
		# App.module("Notebook").start()
		# App.module("User").start()
		# App.module("Feat").start()
		# App.module("Modview").start()
		# App.module("Tag").start()

	App.on "initialize:after", ->
		if Backbone.history
			Backbone.history.start()
			# {pushState:true}

	App

$ ->
	Notable.start()