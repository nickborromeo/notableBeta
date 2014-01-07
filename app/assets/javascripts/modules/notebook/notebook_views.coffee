@Notable.module("Notebook", (Notebook, App, Backbone, Marionette, $, _) ->

	class Notebook.TrunkView extends Marionette.ItemView
		template: "notebook/trunkModel"
		tagName: "li"
		className: "trunk"
		events: ->
			"dblclick label": "openEdit" #done
			"keypress .edit": "closeEdit" #done
			"blur .edit": "updateTrunk" #done
			"click .remove": "removeTrunk" #done
			"click li": "selectTrunk" #done

		initialize: ->
			@listenTo @model, 'change', @render
			@listenTo @model, 'destroy', @remove
		ui:
			input: "input.edit"

		selectTrunk: ->
			$(".trunk").removeClass("selected")
			@$el.addClass("selected")
			# App.Notebook.activeTrunk = (selected notebook in the sidebar)
			# Show the appropriate notebook in the contentRegion
			#   Note.compileTree(activeTree)
			#   Note.$el.render()
		openEdit: ->
			@$el.addClass('editing')
			@ui.input.focus()
		closeEdit: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				@updateTrunk()
		updateTrunk: ->
			newTitle = @ui.input.val().trim()
			if newTitle
				@model.save
					title: newTitle
					# modview: modview
			else
				@removeTrunk()
			@$el.removeClass('editing')
		removeTrunk: ->
			# Add safety mechanism to ask "Are you sure? Yes/No."
			if Notebook.forest.length > 1
				@model.destroy()
				App.Notify.alert 'deleteNotebook', 'warning'
			else
				App.Notify.alert 'needsNotebook', 'danger'

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