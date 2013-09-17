@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.ModelView extends Marionette.ItemView
		template: "note/noteModel"
		className: "note-item"
		ui:
			noteContent: ".noteContent"

		events:
			"click .destroy": "deleteNote"
			"blur .noteContent": "updateNote"
		initialize: ->
			@listenTo @model, "change", @render
		testEvent: ->
			console.log "some text"
			# ENTER_KEY = 13
			# if e.which is ENTER_KEY

		onRender: ->
			@ui.noteContent.wysiwyg()
		deleteNote: ->
			@model.destroy()
		updateNote: (e) ->
			noteText = @ui.noteContent.html().trim()
			if noteText
				@model.set("title", noteText).save()

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView

		initialize: ->
			@listenTo @collection, "all", @update

		onRender: ->
			@update()
		update: ->
			reduceCompleted = (left, right) ->
				left and right.get("completed")
			allCompleted = @collection.reduce(reduceCompleted, true)
			if @collection.length is 0
				@$el.parent().hide()
			else
				@$el.parent().show()

	App.vent.on 'notes:filter', (filter) ->
		filter = filter || 'all';
		$('#noteapp').attr('class', 'filter-' + filter)

)