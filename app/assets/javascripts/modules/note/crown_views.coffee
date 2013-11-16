@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	
	class Note.CrownView extends Marionette.ItemView
		id: "crown"
		template: "note/crownModel"

	class Note.BreadcrumbView extends Marionette.ItemView
		template: "note/breadcrumbModel"
		tagName: "li"
		initalize: ->
			
	class Note.BreadcrumbsView extends Marionette.CollectionView
		id: "breadcrumbs"
		className: "breadcrumb"
		itemView: Note.BreadcrumbView

		appendHtml: (collectionView, itemView, i) ->
			if i is @collection.length - 1
				itemView.template = "note/activeBreadcrumbModel";
				itemView.className = "active"
				itemView.render();
			@$el.append(itemView.el)
		# itemViewOptions: (model, index) ->
		# 	active = index is collection.length - 1
		# 	active: active
)
