@Notable.module("Scaffold.Header", (Header, App, Backbone, Marionette, $, _) ->

	class Header.Model extends Backbone.Model

	class Header.Collection extends Backbone.Collection
		model: Header.Model

	Header.links = new Header.Collection [
		{name: "Search"}
		{name: "Sign Out"}
		{name: "Account"}
	]
	
)