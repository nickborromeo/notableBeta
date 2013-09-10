@Notable.module("Scaffold.Footer", (Footer, App, Backbone, Marionette, $, _) ->

	class Footer.ModelView extends Marionette.ItemView
		template: "scaffold/footer/footer"
		tagName: "span"
)