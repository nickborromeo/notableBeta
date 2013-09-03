@Notable.module("HeaderModule.Default", (Default, App, Backbone, Marionette, $, _) ->

	class Default.HeaderItemView extends Marionette.ItemView
		template: "header/templates/header_item"
		tagName: "li"

	class Default.HeaderView extends Marionette.CompositeView
		template: "header/templates/default_header"
		itemView: Default.HeaderItemView
		itemViewContainer: "ul.nav"
)