@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.TrunkView extends Marionette.ItemView
		template: "notebook/trunkModel"
		tagName: "li"
		className: "trunk"
		events: ->
			"dblclick label": "openEdit"
			"keypress .edit": "closeEdit"
			"blur .edit": "updateTrunk"
			"click .remove": "removeTrunk"
			"click li": "selectTrunk"

		initialize: ->
			@listenTo @model, 'change', @render
			@listenTo @model, 'destroy', @remove
		ui:
			input: ".edit"

		selectTrunk: ->
			$(".trunk").removeClass("selected")
			@$el.addClass("selected")
			# show the appropriate notebook in the contentRegion
		openEdit: ->
			@$el.addClass('editing')
			@ui.input.focus()
		closeEdit: (e) ->
			if e.which = 13
				@updateTrunk()
		updateTrunk: ->
			newTitle = @ui.input.val().trim()
			#trunkGUID = @generateGuid
			if newTitle
				@model.save()
					title: newTitle
					# modview: modview
					# guid: trunkGUID
			else
				@removeTrunk()
			@$el.removeClass('editing')
		removeTrunk: ->
			@model.destroy()

	class Notebook.ForestView extends Marionette.CollectionView
		id: "forest"
		tagName: "ul"
		# template: "notebook/forestCollection"
		itemView: Notebook.TrunkView

		# appendHtml: (compositeView, itemView) ->
		# 	console.log compositeView.$el.children
		# 	# .lastChild.before("<p>Test</p>")
		# 	compositeView.$el.append(itemView.el)

)