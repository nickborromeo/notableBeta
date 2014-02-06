@Notable.module "Evernote", (Evernote, App, Backbone, Marionette, $, _) ->

	class Evernote.Notebook extends Backbone.Model
		defaults:
			selected: false

		isSelected: ->
			@get 'selected'

	class Evernote.Notebooks extends Backbone.Collection
		url: '/sync'
		model: Evernote.Notebook

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
						checkbox = new Evernote.Notebook notebook
						@add checkbox
				@sync() if @isEmpty()
		sync: ->
			selectedNotebooks = @getSelected()
			App.Helper.eventManager.trigger "showProgress"
			App.Helper.eventManager.trigger "intervalProgress"
			$.post @url, notebooks: selectedNotebooks, (data) ->
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

