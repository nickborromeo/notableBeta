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
				sel = window.getSelection()
				title = @model.attributes.title
				# @updateNote
				text = @textBeforeCursor(sel, title)
				@textAfterCursor(sel, title)
				@ui.noteContent.html(text)
		updateNote: (e) ->
			noteTitle = @ui.noteContent.html().trim()
			if noteTitle
				@model.save
					title: noteTitle
		deleteNote: ->
			@model.destroy()

		setCursor: (e) ->
			@ui.noteContent.focus()
		textBeforeCursor: (sel, title) ->
			textBefore = title.slice(0,sel.anchorOffset)
			@model.save
				title: textBefore
			return textBefore
		textAfterCursor: (sel, title) ->
			# console.log title
			textAfter = title.slice(sel.anchorOffset, title.length)
			# console.log textAfter
			@model.collection.create
				title: textAfter

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
)