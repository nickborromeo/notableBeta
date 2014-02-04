@Notable.module("Notify", (Notify, App, Backbone, Marionette, $, _) ->
	class Notify.SaveView extends Marionette.ItemView
		template: 'notification/save'
		onRender: =>
			@$el.fadeIn(Notify._fadeOutTime + 100)

	class Notify.AlertView extends Marionette.ItemView
		template: 'notification/alert'
		events:
			'click .undo-note-delete': 'undoNoteDelete'
			'click .undo-notebook-delete': 'undoNotebookDelete'
			'click .closeAlert': 'closeAlert'

		initialize: ->
			if @model.get('selfDestruct')
				@timeoutID = setTimeout (=>
					@model.collection.remove @model
				), @model.get('destructTime')

		undoNoteDelete: (event) =>
			event.stopPropagation()
			event.preventDefault()
			App.Action.manager.undo()
		undoNotebookDelete: (event) =>
			event.stopPropagation()
			event.preventDefault()
			console.log "Undo notebook deletion"
		closeAlert: (event) =>
			event.stopPropagation()
			@model.collection.remove @model

		remove: =>
			clearTimeout @timeoutID
			@$el.fadeOut Notify._fadeOutTime, =>
				@$el.remove()

	class Notify.AlertsView extends Marionette.CollectionView
		itemView: Notify.AlertView
		emptyView: Notify.SaveView

)