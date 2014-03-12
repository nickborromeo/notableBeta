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
			@showProgressView(selectedNotebooks)
			$.post @url, notebooks: selectedNotebooks, (data) ->
				App.Note.noteController.reset ->
					if data.code is 0
						App.Notify.alert 'evernoteRateLimit', 'warning', {selfDestruct: false, retryTime: data.retryTime}
					else if data.code is 1
						App.Notify.alert 'evernoteError', 'warning', {destructTime: 14000}
					else if data.code is 2
						App.Notify.alert 'evernoteSync', 'success', {destructTime: 9000}
					App.Notebook.forest.fetch data: user_id: App.User.activeUser.id

		showProgressView: (selectedNotebooks) ->
			App.Helper.eventManager.trigger "showProgress"
			if selectedNotebooks.length > 14
				App.Helper.eventManager.trigger "intervalProgress"
			else
				App.Helper.eventManager.trigger "intervalProgressLong"
		hideControls: ->
			$("#modview-region").hide()
			$(".message-template").hide()
			$("#notebook-title").css("opacity", "0")