@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.TrunkView extends Marionette.CompositeView
		template: "notebook/trunkModel"
		tagName: "li"
		className: "trunk"
		events: ->
			"click li": "selectTrunk"
			"dblclick label": "openEdit"
			"keypress .edit": "closeEdit"
			"blur .edit": "updateTrunk"
			"click .remove": "removeTrunk"

		initialize: ->
			@listenTo @model, 'change', @render
			@listenTo @model, 'destroy', @remove
		render: ->
			@$el.html @template( @model.toJSON() )
			@$input = @$('.edit')

		selectTrunk: ->
			$(".trunk").removeClass("selected")
			@$el.addClass("selected")
			# show the appropriate notebook in the contentRegion
		openEdit: ->
			@$el.addClass('editing')
			@$el.input.focus()
		closeEdit: (e) ->
			if e.which = 13
				@updateTrunk()
		updateTrunk: ->
			newTitle = @$input.val().trim()
			#trunkGUID = @generateGuid
			if newTitle
				@model.save
					title: newTitle
					# modview: modview
					# guid: trunkGUID
			else
				@removeTrunk
			@$el.removeClass('editing')
		removeTrunk: ->
			@model.destroy

	class Notebook.ForestView extends Marionette.CollectionView
		id: "forest"
		itemView: Notebook.TrunkView

		initialize: ->

)