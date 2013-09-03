@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.Header extends Backbone.Model

	class Default.Headers extends Backbone.Collection
		model: Default.Header

	API =
		getHeaders: ->
			new Default.Headers [
				{name: "Search"}
				{name: "Sign Out"}
				{name: "Account"}				
			]

	App.reqres.setHandler("headerLinks", ->
		API.getHeaders()
	)
)