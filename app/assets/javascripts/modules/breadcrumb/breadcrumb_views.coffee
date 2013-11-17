@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.BreadcrumbView extends Marionette.ItemView
		template: "breadcrumb/breadcrumb"
		className: "chain-breadcrumb"
		tagName: "li"

	class Note.BreadcrumbsView extends Marionette.CollectionView
		id: "breadcrumb"
		className: "breadcrumb"
		tagName: "ol"
		itemView: Note.BreadcrumbView

		appendHtml: (collectionView, itemView, i) ->
			if i is 0
				itemView.$el.attr("class", "root-breadcrumb")
			else
				if i is @collection.length - 1
					itemView.template = "breadcrumb/activeBreadcrumb";
					itemView.className = "chain-breadcrumb"
					itemView.render();
			@$el.append(itemView.el)

	class Note.NotebookTitleView extends Marionette.ItemView
		id: "notebook-title"
		className: "hidden-xs"
		tagName: "h3"
		template: "breadcrumb/notebookTitle"
)
