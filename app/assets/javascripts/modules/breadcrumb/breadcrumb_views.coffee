@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BreadcrumbView extends Marionette.ItemView
		template: "breadcrumb/breadcrumb"
		tagName: "li"

	class Note.BreadcrumbsView extends Marionette.CollectionView
		id: "breadcrumbs"
		className: "breadcrumb"
		itemView: Note.BreadcrumbView

		appendHtml: (collectionView, itemView, i) ->
			if i is @collection.length - 1
				itemView.template = "breadcrumb/activeBreadcrumb";
				itemView.className = "active"
				itemView.render();
			@$el.append(itemView.el)
)
