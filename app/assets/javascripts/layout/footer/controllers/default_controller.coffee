@Notable.module("FooterModule.Default", (Default, App, Backbone, Marionette, $, _) ->
	Default.Controller =

		showFooter: ->
			footerView = @createFooterView()
			App.footerRegion.show footerView
		createFooterView: ->
			new Default.FooterView

)