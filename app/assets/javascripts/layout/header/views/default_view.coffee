@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.HeaderView extends Marionette.ItemView
		template: "header/templates/default"
		tagName: "li"

	class Default.HeadersView extends Marionette.CompositeView
		template: "header/templates/defaults"
		itemView: Default.HeaderView
		itemViewContainer: "ul.nav"
)