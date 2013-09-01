@Notable = do (Backbone, Marionette) ->
	#create the application root object
	App = new Marionette.Application

	App.addRegions
		headerRegion: "#header-region"
		mainRegion: "#main-region"
		sidebarRegion: "#sidebar-region"
		footerRegion: "#footer-region"

	App.on "initialize:after", ->
		if Backbone.history
			Backbone.history.start()
			# {pushState:true} 
	App

# $ ->
# 	Notable.start(options)
# 	App.start(options)