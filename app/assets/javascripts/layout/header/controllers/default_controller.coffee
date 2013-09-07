@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	Default.Controller =

		showHeader: ->
			headerView = @createHeaderView(Default.links)
			App.headerRegion.show headerView
		createHeaderView: (links) ->
			new Default.HeadersView
				collection: links
)