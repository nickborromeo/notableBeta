@Notable.module("FooterModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.FooterView extends Marionette.ItemView
		template: "footer/templates/default_footer"
		tagName: "span"
)