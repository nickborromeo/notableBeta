@Notable = do (Backbone, Marionette) ->
	# Create application root object and default regions
	App = new Marionette.Application

	App.addRegions
		messageRegion: "#message-region"
		contentRegion: "#content-region"
		sidebarRegion: "#sidebar-region"

	# Run BEFORE/DURING/AFTER initializers
	App.on "initialize:before", ->
		App.module("Scaffold").start()

	App.addInitializer ->
		App.module("Notebook").start()
		App.module("Note").start()
		App.module("Action").start()
		# App.module("Notification").start()
		# App.module("Notebook").start()
		# App.module("Feat").start()
		# App.module("Modview").start()
		# App.module("Tag").start()

	App.on "initialize:after", ->
		App.module("Wiring").start()
		if Backbone.history
			Backbone.history.start()
			# {pushState:true}

	App

$ ->
	Notable.start()
