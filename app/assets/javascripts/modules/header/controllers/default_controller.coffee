@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->
	Default.Controller =

		showHeader: ->
			App.headerRegion.show @createHeaderView()
		createHeaderView: ->
			new Default.HeaderView

)