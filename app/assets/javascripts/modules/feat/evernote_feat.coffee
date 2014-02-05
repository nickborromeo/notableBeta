@Notable.module "Feat", (Feat, App, Backbone, Marionette, $, _) ->

	class Feat.EverNotebook extends Backbone.Model
		defaults:
			selected: false

		isSelected: ->
			@get 'selected'

	class Feat.EverNotebooks extends Backbone.Collection
		url: '/fetchNotebooks'
		model: Feat.EverNotebook

		getSelected: ->
			checkboxSelected = @filter (notebook) ->
				notebook.isSelected()
			selected = []
			_(checkboxSelected).each (notebook) ->
				selected.push
					name: notebook.get('name')
					eng: notebook.get('guid')
			selected

		fetch: ->
			@hideControls()
			$.get @url, (data) =>
				_(data).each (notebook) =>					
					if notebook? and not App.Notebook.forest.findWhere(eng: notebook.guid)?
						checkbox = new Feat.EverNotebook notebook
						@add checkbox
				@sync() if @isEmpty()
		sync: ->
			selectedNotebooks = @getSelected()
			App.Helper.eventManager.trigger "showProgress"
			App.Helper.eventManager.trigger "intervalProgress"
			$.post '/sync', notebooks: selectedNotebooks, (data) ->
				App.Note.noteController.reset ->
					if data.code is 1
						App.Notify.alert 'evernoteSync', 'success', {destructTime: 9000}
					else
						App.Notify.alert 'evernoteRateLimit', 'warning', {selfDestruct: false, retryTime: data.retryTime}
					App.Notebook.forest.fetch data: user_id: App.User.activeUser.id

		hideControls: ->
			$("#modview-region").hide()
			$(".message-template").hide()
			$("#notebook-title").css("opacity", "0")

	class Feat.CheckboxView extends Marionette.ItemView
		template: "feat/checkbox"
		className: "en-checkbox"

		events:
			"click": "select"

		select: ->
			console.log "clicked #{@model.get('name')}", arguments
			selected = @$(".notebook_selection")[0].checked
			@model.set 'selected', selected

	class Feat.CheckboxesView extends Marionette.CollectionView
		itemView: Feat.CheckboxView
		className: "en-checkboxes"

	class Feat.EverNotebookView extends Marionette.Layout
		template: "feat/everNotebook"
		id: "ever-notebook"
		regions:
			checkboxRegion: "#checkbox-region"

		events:
			"click .continue": "continueSync"
			"click .cancel": "cancelSync"

		continueSync: ->
			App.Feat.everNotebooks.sync()
		cancelSync: ->
			App.Note.noteController.reset()
