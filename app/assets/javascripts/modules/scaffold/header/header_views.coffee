@Notable.module("Scaffold.Header", (Header, App, Backbone, Marionette, $, _) ->

	class Header.ModelView extends Marionette.ItemView
		template: "<title>{{name}}</title>"
		tagName: "li"

	class Header.CollectionView extends Marionette.CompositeView
		template: "scaffold/header/header"
		itemView: Header.ModelView
		itemViewContainer: "ul.nav"
)