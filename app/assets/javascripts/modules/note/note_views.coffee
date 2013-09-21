@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->

	class Note.ModelView extends Marionette.ItemView
		template: "note/noteModel"
		className: "note-item"
		ui:
			noteContent: ".noteContent"
		events:
			"keypress .noteContent": "createNote"
			"blur .noteContent": "updateNote"
			"click .destroy": "deleteNote"

		initialize: ->
			@listenTo @model, "change:created_at", @setCursor
		onRender: ->
			@ui.noteContent.wysiwyg()

		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				newNote = @.model.collection.create
					title: ""
		updateNote: (e) ->
			noteTitle = @ui.noteContent.html().trim()
			if noteTitle
				@model.set("title", noteTitle).save()
		deleteNote: ->
			@model.destroy()
		setCursor: (e) ->
			@ui.noteContent.focus()

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
)