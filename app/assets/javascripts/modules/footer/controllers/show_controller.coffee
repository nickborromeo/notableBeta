@Notable.module("FooterModule.Show", (Show, App, Backbone, Marionette, $, _) ->

	Show.controller =

		showFooter: ->
			App.footerRegion.show @createFooterView()
		createFooterView: ->
			new Show.FooterView

)