@Notable.module("FooterModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.FooterView extends Marionette.ItemView
		template: "default_footer"
		tagName: "span"
)