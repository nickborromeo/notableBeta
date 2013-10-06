@Notable.module("Note", (Note, App, Backbone, Marionette, $, _) ->
	Note.eventManager = _.extend {}, Backbone.Events # Event Manager

	class Note.ModelView extends Marionette.ItemView # Note.ItemViewEvents
		template: "note/noteModel"
		className: "note-item"
		ui:
			noteContent: ".noteContent"
		events:
			"keypress .noteContent": "createNote"
			"blur .noteContent": "updateNote"
			"click .destroy": "triggerDelete"
			"click .tab": "triggerTabNote"
			"click .untab": "triggerUnTabNote"

		initialize: ->
			@listenTo @model, "change:created_at", @setCursor
		onRender: ->
			@ui.noteContent.wysiwyg()

		triggerTabNote: ->
			Note.eventManager.trigger 'tabNote', @model
		triggerUnTabNote: ->
			Note.eventManager.trigger 'unTabNote', @model
		triggerDelete: ->
			Note.eventManager.trigger 'deleteNote', @model

		createNote: (e) ->
			ENTER_KEY = 13
			if e.which is ENTER_KEY
				e.preventDefault()
				sel = window.getSelection()
				title = @updateNote()
				textBefore = @textBeforeCursor sel, title
				textAfter = @textAfterCursor sel, title
				@ui.noteContent.html textBefore
				Note.eventManager.trigger 'createNote', @model, textAfter
		updateNote: ->
			noteTitle = @ui.noteContent.html().trim()
			@model.save
				title: noteTitle
			noteTitle
 
		setCursor: (e) ->
			@ui.noteContent.focus()
		textBeforeCursor: (sel, title) ->
			textBefore = title.slice(0,sel.anchorOffset)
			@model.save
				title: textBefore
			textBefore
		textAfterCursor: (sel, title) ->
			textAfter = title.slice(sel.anchorOffset, title.length)

	class Note.CollectionView extends Marionette.CollectionView
		id: "note-list"
		itemView: Note.ModelView
		initialize: ->
			@listenTo @collection, "sort", @render
			Note.eventManager.on 'createNote', @createNote, this
			Note.eventManager.on 'tabNote', @tabNote, this
			Note.eventManager.on 'unTabNote', @unTabNote, this
			Note.eventManager.on 'deleteNote', @deleteNote, this
		createNote: (precedent, text) ->
			@collection.createNote precedent, text
		tabNote: (note) ->
			@collection.tabNote note
		unTabNote: (note) ->
			@collection.unTabNote @collection.search 187
		deleteNote: (note) ->
			@collection.deleteNote note

)
