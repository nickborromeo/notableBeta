@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.Header extends Backbone.Model

	class Default.Headers extends Backbone.Collection
		model: Default.Header

	Default.links = new Default.Headers [
		{name: "Search"}
		{name: "Sign Out"}
		{name: "Account"}				
	]
	
)