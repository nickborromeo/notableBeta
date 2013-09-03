@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->
	Default.Controller =

		showHeader: ->
			links = @getLinksCollection()
			headerView = @createHeaderView(links)
			App.headerRegion.show headerView
		getLinksCollection: ->
			new Backbone.Collection [
				{name: "Search"}
				{name: "Sign Out"}
				{name: "Account"}				
			]
		createHeaderView: (links) ->
			new Default.HeadersView
				collection: links
)