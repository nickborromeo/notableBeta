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
			"click": "selectTrunk"

		initialize: ->
			@listenTo @model, 'change', @render
			@listenTo @model, 'destroy', @remove
			@listenTo @model, 'created', @createTrunk
			@listenTo @model, 'select', @selectTrunk
			@listenTo @model, 'selected', @createFirstNote

		ui:
			input: "input.edit"

		selectTrunk: ->
			$(".trunk").removeClass("selected")
			@$el.addClass("selected")
			if @model isnt App.Notebook.activeTrunk
				selectTrunkCb = =>
					App.Notebook.activeTrunk = @model
					App.Note.eventManager.trigger "activeTrunk:changed"
				if App.Action.transporter.storage.hasChangesToSync()
					App.Note.initializedTree.then ->
						App.Action.orchestrator.triggerSaving(selectTrunkCb)
				else
					selectTrunkCb()
		createTrunk: ->
			@selectTrunk()
			App.Notify.alert 'newNotebook', 'success', {destructTime: 5000}
			window.setTimeout ->
				App.Helper.eventManager.trigger "closeSidr"
			, 500
		createFirstNote: ->
			if App.Note.tree.isEmpty()
				newNote = new App.Note.Branch
				newNoteAttrs = notebook_id: App.Notebook.activeTrunk.id
				App.Action.orchestrator.triggerAction 'createBranch', newNote, newNoteAttrs
				App.Note.tree.create newNote
				App.Note.eventManager.trigger "setCursor:#{App.Note.activeTree.last().get('guid')}"

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
				App.Note.eventManager.trigger "activeTrunk:changed"
			else
				@removeTrunk()
			@$el.removeClass('editing')
		removeTrunk: (e) ->
			e.stopPropagation()
			if Notebook.forest.length > 1
				if @confirmIntention()
					@destroyNotebook()
			else
				App.Notify.alert 'needsNotebook', 'danger'
		confirmIntention: ->
			if App.Note.activeTree.length >= 3
				confirm "Are you sure you want to remove this notebook?"
			else
				return true
		destroyNotebook: ->
			options =
				success: (model, response, opts) =>
					if model is App.Notebook.activeTrunk
						App.Notebook.activeTrunk = App.Notebook.forest.first()
						App.Note.eventManager.trigger "activeTrunk:changed"
						$(".trunk").removeClass("selected")
						$("#forest li:first-child").addClass("selected")
				error: (model, response, opts) =>
					console.log reponse.message
			@model.destroy(options)
			App.Notify.alert 'deleteNotebook', 'warning'

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
