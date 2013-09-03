@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->
	Default.Controller =

		showHeader: ->
			links = App.request "headerLinks"
			console.log links
			headerView = @createHeaderView(links)
			App.headerRegion.show headerView

		createHeaderView: (links) ->
			new Default.HeadersView
				collection: links
)