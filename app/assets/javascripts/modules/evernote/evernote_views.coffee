@Notable.module "Evernote", (Evernote, App, Backbone, Marionette, $, _) ->

	class Evernote.CheckboxView extends Marionette.ItemView
		template: "feat/checkbox"
		className: "en-checkbox"

		events:
			"click": "select"

		select: ->
			selected = @$(".notebook_selection")[0].checked
			@model.set 'selected', selected

	class Evernote.CheckboxesView extends Marionette.CollectionView
		itemView: Evernote.CheckboxView
		className: "en-checkboxes"

	class Evernote.NotebookView extends Marionette.Layout
		template: "feat/everNotebook"
		id: "ever-notebook"
		regions:
			checkboxRegion: "#checkbox-region"

		events:
			"click .continue": "continueSync"
			"click .cancel": "cancelSync"

		continueSync: ->
			App.Evernote.notebooks.sync()
		cancelSync: ->
			App.Note.noteController.reset()
