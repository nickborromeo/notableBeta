@Notable.module("FooterModule.Show", (Show, App, Backbone, Marionette, $, _) ->

	class Show.FooterView extends Marionette.ItemView
		template: "show_footer"
		tagName: "span"
)