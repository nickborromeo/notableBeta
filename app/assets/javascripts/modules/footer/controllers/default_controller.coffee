@Notable.module("FooterModule.Default", (Default, App, Backbone, Marionette, $, _) ->
	Default.Controller =

		showFooter: ->
			App.footerRegion.show @createFooterView()
		createFooterView: ->
			new Default.FooterView

)